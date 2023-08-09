# main.py

from fastapi import FastAPI,UploadFile,Request,Response,HTTPException,File
import certops
from fastapi.responses import FileResponse
from pydantic import BaseModel
import tempfile
import zipfile
from cryptography.hazmat.primitives import serialization
from cryptography import x509
from cryptography.x509 import ocsp
import datetime
from cryptography.hazmat.primitives import hashes
import os
from datetime import datetime
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID
from datetime import datetime, timedelta
import base64

app = FastAPI()

class CertificateRequest(BaseModel):
    generate_new: bool
    name: str
    hostname: str
    subject_name: str
    passphrase: str
    ip_address: str
    
    

@app.get("/get_serial_no")
async def get_serial_no(data: str):
    filename = data
    sno=certops.get_serial_no(filename)
    return sno

@app.post("/get_new_certificate")
async def create_new_key(request: CertificateRequest, sr_no: int | None=None):
    if request.generate_new:
        certops.create_new_keys(request.name,request.passphrase)
        public_key=certops.load_public_key(f"{request.name}/{request.name}_pub.pem")
        private_key=certops.load_private_key(f"{request.name}/{request.name}.pem",request.passphrase)

    # elif pub_key is not None:
    #    return {"filename": pub_key.filename}
    
        # with tempfile.NamedTemporaryFile(delete=False) as tmp:
        #     tmp.write(await pub_key.read())
        #     tmp_path = tmp.name

        # try:
        #     with open(tmp_path, "rb") as f:
        #         public_key = certops.load_public_key(f.read())

        # finally:
        #     os.remove(tmp_path)

    else:
        return {"error_message": "Please provide a public key or choose to generate new keys"}

    certificate = certops.create_certificate(
        public_key=public_key,
        ipadd=request.ip_address,
        hostname=request.hostname,
        subject_name=request.subject_name,
        sr_no=sr_no
    )
    ca = certops.load_certificate('ca.pem')
    if request.generate_new:
        with open(f"{request.name}/{request.name}-cert.pem", "wb") as f:
            out1 = certificate.public_bytes(encoding=serialization.Encoding.PEM)
            out2 = ca.public_bytes(encoding=serialization.Encoding.PEM)
            out = (out1+out2)
            f.write(out)
        zip_path = f"{request.name}/{request.name}.zip"
        with zipfile.ZipFile(zip_path, "w") as zip_file:
            zip_file.write(f"{request.name}/{request.name}-cert.pem", arcname=f"{request.name}-cert.pem")
            zip_file.write(f"{request.name}/{request.name}_pub.pem", arcname=f"{request.name}_pub.pem")
            zip_file.write(f"{request.name}/{request.name}.pem", arcname=f"{request.name}.pem")
        return FileResponse(zip_path, filename=f"{request.name}.zip")

    else:
        certificate_path = f"{request.subject_name}/{request.subject_name}.pem"
        with open(certificate_path, "wb") as f:
            f.write(certificate.public_bytes(encoding=serialization.Encoding.PEM))

        return FileResponse(certificate_path)
    

@app.get("/create_new_crl")
async def create_new_crl(file_name: str | None=None):
    revocation_list = []
    if file_name:
        certops.build_crl(revocation_list,file_name)
    else:
        file_name = 'crl.pem'
        certops.build_crl(revocation_list,file_name)

@app.get("/update_revocation_list")
async def update_crl(name: str):
    msg = certops.revoke_certificate(name)
    return msg

@app.get('/get_revoked_cert_list')
async def get_revok_list(crl_name: str | None=None):
    rev = []
    if crl_name:
        crl = certops.get_crl(crl_name)
    else:
        crl = certops.get_crl('crl.pem')
    for a in crl:
        rev.append(a.serial_number)
    return rev

@app.get('/get_crl')
async def get_crl(crl_name: str | None=None):
    if crl_name:
        crl = certops.get_crl(crl_name)
    else:
        crl = certops.get_crl('crl.pem')
    crl_pem_data = crl.public_bytes(serialization.Encoding.PEM)
    headers = {
        "Content-Disposition": "attachment; filename=crl_file.crl"
    }
    return Response(content=crl_pem_data, headers=headers, media_type="application/pkix-crl")

    
@app.get('/get_issuer_cert')
async def get_crt(crt_name: str | None=None):
    if crt_name:
        crt = certops.load_certificate(crt_name)
    else:
        crt = certops.load_certificate('ca.pem')
    ca_pem_data = crt.public_bytes(serialization.Encoding.DER)
    headers = {
        "Content-Disposition": "attachment; filename=cert.der"
    }
    return Response(content=ca_pem_data, headers=headers, media_type="application/octet-stream")

# @app.get('/ocsp', response_class=Response)
# async def handle_ocsp_request(ocsp_req: str):
#     try:
#         certificate_to_check = certops.load_certificate(ocsp_req)
#         root_ca_cert = certops.load_certificate('ca.pem')
#         responder_cert = certops.load_certificate('responder/responder-cert.pem')
#         responder_key = certops.load_private_key('responder/responder.pem','responder')
#         builder = ocsp.OCSPRequestBuilder()
#         builder = builder.add_certificate(certificate_to_check, root_ca_cert, hashes.SHA256())
#         ocsp_request = builder.build()
#     except ValueError as e:
#         print(e)
#         raise HTTPException(status_code=400, detail="Invalid OCSP request")

#     # Implement your OCSP response logic here
#     # You need to check the OCSP request against the revocation status of the certificates issued by your CA
#     crllist = certops.get_crl('crl.pem')
#     for a in crllist:
#         if a.serial_number == certificate_to_check.serial_number:
#             cert_status = ocsp.OCSPCertStatus.REVOKED
#             timeOfRevocation = a.revocation_date
#             reason = x509.ReasonFlags.unspecified
#         else:
#             cert_status = ocsp.OCSPCertStatus.GOOD
#             timeOfRevocation = None
#             reason = None
   
   
#     basic_response = ocsp.OCSPResponseBuilder()
#     basic_response = basic_response.add_response(
#         cert=certificate_to_check,
#         issuer=root_ca_cert,
#         algorithm=hashes.SHA256(),
#         cert_status=cert_status,
#         this_update=datetime.datetime.now(),
#         next_update=datetime.datetime.now(),
#         revocation_time=timeOfRevocation,
#         revocation_reason=reason
#     ).responder_id(
#         ocsp.OCSPResponderEncoding.HASH,
#         responder_cert
#     )
    
#     ocsp_response = basic_response.sign(responder_key, hashes.SHA256())
#     print(ocsp_response.certificate_status.name)
#     return ocsp_response.certificate_status.name


@app.get('/ocsp', response_class=Response)
async def handle_ocsp_request(ocsp_req: str):
    try:
        # Certificate loading and OCSP request building code
        certificate_to_check = certops.load_certificate(ocsp_req)
        root_ca_cert = certops.load_certificate('ca.pem')
        responder_cert = certops.load_certificate('responder/responder-cert.pem')
        responder_key = certops.load_private_key('responder/responder.pem','responder')
        builder = ocsp.OCSPRequestBuilder()
        builder = builder.add_certificate(certificate_to_check, root_ca_cert, hashes.SHA256())
        ocsp_request = builder.build()
        # Check the OCSP request against the revocation status of the certificates issued by your CA
        crl_list = certops.get_crl('crl.pem')
        for a in crl_list:
            if a.serial_number == certificate_to_check.serial_number:
                cert_status = ocsp.OCSPCertStatus.REVOKED
                time_of_revocation = a.revocation_date
                reason = x509.ReasonFlags.unspecified
                break
        else:
            cert_status = ocsp.OCSPCertStatus.GOOD
            time_of_revocation = None
            reason = None

        # Build the OCSP response
        basic_response = ocsp.OCSPResponseBuilder()
        basic_response = basic_response.add_response(
            cert=certificate_to_check,
            issuer=root_ca_cert,
            algorithm=hashes.SHA256(),
            cert_status=cert_status,
            this_update=datetime.now(),
            next_update=datetime.now(),
            revocation_time=time_of_revocation,
            revocation_reason=reason
        ).responder_id(
            ocsp.OCSPResponderEncoding.HASH,
            responder_cert
        )

        ocsp_response = basic_response.sign(responder_key, hashes.SHA256())

        if cert_status == ocsp.OCSPCertStatus.REVOKED:
            response = Response()
            response.status_code = 403  # Forbidden
            response.headers['Content-Type'] = 'text/html'
            response.headers['Content-Length'] = '0'
            response.headers['Connection'] = 'close'
            response.headers['Strict-Transport-Security'] = 'max-age=31536000'
            response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate'
            response.headers['Pragma'] = 'no-cache'
            response.headers['Expires'] = '0'
            response.headers['OCSP-Response'] = base64.b64encode(ocsp_response.public_bytes(serialization.Encoding.DER)).decode('utf-8')
            response.headers['SSL-Certificate-Status'] = 'revoked'
            return response

        # Return a normal response if the certificate is not revoked
       # print(ocsp_response.certificate_status.name)
        return ocsp_response.certificate_status.name

    except ValueError as e:
        print(e)
        raise HTTPException(status_code=400, detail="Invalid OCSP request")