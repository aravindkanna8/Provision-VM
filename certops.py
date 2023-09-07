import datetime
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from cryptography.x509.oid import NameOID
from cryptography.x509 import (
    CRLDistributionPoints, DistributionPoint, Extension,
    AuthorityInformationAccessOID, ExtendedKeyUsageOID,
    SubjectAlternativeName, DNSName, IPAddress
)
import os
import re
import subprocess
import ipaddress
 
def get_serial_no(data):
    with open(data, 'rb') as file:
        cert_data = file.read()
    cert = x509.load_pem_x509_certificate(cert_data, default_backend())
    return cert.serial_number

def get_crl(data):
    with open(data, 'rb') as file:
        cert_data = file.read()
    return x509.load_pem_x509_crl(cert_data)

def load_private_key(file_path, password=None):
    with open(file_path, 'rb') as key_file:
        key_data = key_file.read()
    if password:
        password = password.encode('utf-8')
    private_key = serialization.load_pem_private_key(
        key_data,
        password=password,
        backend=default_backend()
    )
    return private_key

def load_public_key(file_path):
    with open(file_path, 'rb') as key_file:
        key_data = key_file.read()
       

    public_key = serialization.load_pem_public_key(
        key_data,
        backend=default_backend()
    )

    return public_key


def load_certificate(file_path):
    with open(file_path, 'rb') as file:
        certificate = x509.load_pem_x509_certificate(file.read(), default_backend())
    return certificate



def build_crl(revoked_certificates, file_name):
    crl_private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048
    )
    issuer_private_key=load_private_key('ca-key.pem',password='novell')
    issuer_certificate=load_certificate('ca.pem')
    builder = x509.CertificateRevocationListBuilder()
    builder = builder.issuer_name(issuer_certificate.subject)
    builder = builder.last_update(datetime.datetime.utcnow())
    builder = builder.next_update(datetime.datetime.utcnow() + datetime.timedelta(days=30))
    for revoked_certificate in revoked_certificates:
        revoked_cert_serial_number = revoked_certificate.serial_number
        revoked_cert_revocation_date = datetime.datetime.utcnow()
        builder = builder.add_revoked_certificate(
            x509.RevokedCertificateBuilder()
            .serial_number(revoked_cert_serial_number)
            .revocation_date(revoked_cert_revocation_date)
            .build()
        )
    crl = builder.sign(
        private_key=issuer_private_key,
        algorithm=hashes.SHA256(),
        backend=default_backend()
    )

    with open(file_name, "wb") as file:
        file.write(crl.public_bytes(encoding=serialization.Encoding.PEM))
        print("CRL successfully generated and saved to", file_name)

def create_certificate(public_key, ipadd, hostname, subject_name, sr_no=None):
    if sr_no:
        serial_no = sr_no
    else:
        serial_no = x509.random_serial_number()
    
    serial_numbers_file=f"{subject_name}/{subject_name}_sr_no.txt"
    with open(serial_numbers_file, "a") as f:
        f.write(f"{serial_no}\n")

    ca_key = load_private_key('ca-key.pem', password='novell')
    one_day = datetime.timedelta(1, 0, 0)
    builder = x509.CertificateBuilder()
    builder = builder.subject_name(x509.Name([
        x509.NameAttribute(NameOID.COMMON_NAME, f"{subject_name}"),
    ]))
    builder = builder.issuer_name(x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, "IN"),
        x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "KR"),
        x509.NameAttribute(NameOID.LOCALITY_NAME, "BLR"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "MF"),
        x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, "NL"),
        x509.NameAttribute(NameOID.COMMON_NAME, "Amar"),
        x509.NameAttribute(NameOID.EMAIL_ADDRESS, "aamar@gmail.com"),
    ]))
    builder = builder.not_valid_before(datetime.datetime.today() - one_day)
    builder = builder.not_valid_after(datetime.datetime.today() + (one_day * 30))
    builder = builder.serial_number(serial_no)
    builder = builder.public_key(public_key)
    builder = builder.add_extension(
        x509.BasicConstraints(ca=False, path_length=None), critical=True
    )

    # Fetch IPv4 addresses using ipconfig /all
    output = subprocess.check_output(["ipconfig", "/all"], text=True)

    # Extract IPv4 addresses from the output
    ipv4_addresses = re.findall(r"IPv4 Address.*: (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})", output)

    # Generate the Subject Alternative Name extension
    alt_names = [DNSName(hostname), IPAddress(ipaddress.ip_address(ipadd))]

    for ip in ipv4_addresses:
        alt_names.append(IPAddress(ipaddress.ip_address(ip)))

    san_extension = SubjectAlternativeName(alt_names)

    # Add the Subject Alternative Name extension to the certificate builder
    builder = builder.add_extension(san_extension, critical=False)

    crl_url = "http://127.0.0.1:8000/get_crl?crl_name=crl.pem"
    crl_extension = CRLDistributionPoints([
        DistributionPoint(
            full_name=[x509.UniformResourceIdentifier(crl_url)],
            relative_name=None,
            crl_issuer=None,
            reasons=None
        )
    ])
    builder = builder.add_extension(crl_extension, critical=False)

    ca_issuers_url = "http://127.0.0.1:8000/get_issuer_cert?crt_name=ca.pem"
    aia_extension = x509.AuthorityInformationAccess([
        x509.AccessDescription(
            x509.AuthorityInformationAccessOID.CA_ISSUERS,
            x509.UniformResourceIdentifier(ca_issuers_url)
        )
    ])
    builder = builder.add_extension(aia_extension, critical=False)

    # extended_key_usage = x509.ExtendedKeyUsage([ExtendedKeyUsageOID.SERVER_AUTH])
    # builder = builder.add_extension(extended_key_usage, critical=False)
    extended_key_usage = x509.ExtendedKeyUsage([ExtendedKeyUsageOID.SERVER_AUTH, ExtendedKeyUsageOID.CLIENT_AUTH])
    builder = builder.add_extension(extended_key_usage, critical=True)
    key_usage = x509.KeyUsage(
        digital_signature=True,
        key_encipherment=True,
        key_cert_sign=True,
        key_agreement=False,
        content_commitment=False,
        data_encipherment=False,
        crl_sign=False,
        encipher_only=False,
        decipher_only=False
    )
    builder = builder.add_extension(key_usage, critical=True)

    authority_key = x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key())
    builder = builder.add_extension(authority_key, critical=False)

    certificate = builder.sign(
        private_key=ca_key,
        algorithm=hashes.SHA256(),
        backend=default_backend()
    )

    return certificate

def create_new_keys(name, passphrase):
    key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048
    )
    if not os.path.exists(name):
        os.mkdir(name)

    public_key = key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )

    with open(f"{name}/{name}.pem", "wb") as f:
        f.write(key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.BestAvailableEncryption(bytes(f"{passphrase}", 'utf-8')),
        ))

    with open(f"{name}/{name}_pub.pem", "wb") as f:
        f.write(public_key)

    # Generate the CSR
    csr_builder = x509.CertificateSigningRequestBuilder().subject_name(
        x509.Name([
            x509.NameAttribute(x509.NameOID.COMMON_NAME, name),
        ])
    )
    csr = csr_builder.sign(key, hashes.SHA256())

    with open(f"{name}/{name}.csr", "wb") as f:
        f.write(csr.public_bytes(serialization.Encoding.PEM))

    print('Keys and CSR generated successfully')


def revoke_certificate(revoke_cert):
    cert_to_revoke = load_certificate(revoke_cert)
    ca_crt = load_certificate('ca.pem')
    ca_key = load_private_key('ca-key.pem', password='novell')

    crl = get_crl('crl.pem')

    builder = x509.CertificateRevocationListBuilder()
    builder = builder.issuer_name(crl.issuer)
    builder = builder.last_update(crl.last_update)
    builder = builder.next_update(datetime.datetime.now() + datetime.timedelta(1, 0, 0))

    for i in range(len(crl)):
        builder = builder.add_revoked_certificate(crl[i])

    ret = crl.get_revoked_certificate_by_serial_number(cert_to_revoke.serial_number)

    if not isinstance(ret, x509.RevokedCertificate):
        revoked_cert = x509.RevokedCertificateBuilder()\
            .serial_number(cert_to_revoke.serial_number)\
            .revocation_date(datetime.datetime.now()).build(backend=default_backend())
        builder = builder.add_revoked_certificate(revoked_cert)

        # Store the serial number in a separate text file
        if not os.path.exists("revoked_serial_numbers.txt"):
            open("revoked_serial_numbers.txt", "a").close()
        
        with open("revoked_serial_numbers.txt", "a") as file:
            file.write(str(cert_to_revoke.serial_number) + "\n")

    cert_revocation_list = builder.sign(
        private_key=ca_key,
        algorithm=hashes.SHA256(),
        backend=default_backend()
    )

    with open("crl.pem", "wb") as f:
        f.write(cert_revocation_list.public_bytes(serialization.Encoding.PEM))

    return f"Updated CRL, added certificate {cert_to_revoke.serial_number} to the list"


def create_root_ca_certificate():
    ca = load_private_key('ca-key.pem', "novell")
    subject_name = x509.Name([
        x509.NameAttribute(x509.NameOID.COMMON_NAME, "Amar"),
    ])
    issuer_name = x509.Name([
        x509.NameAttribute(x509.NameOID.COMMON_NAME, "Amar"),
    ])
    builder = x509.CertificateBuilder()
    builder = builder.subject_name(subject_name)
    builder = builder.issuer_name(issuer_name)
    builder = builder.not_valid_before(datetime.datetime.utcnow())
    builder = builder.not_valid_after(datetime.datetime.utcnow() + datetime.timedelta(days=3650))  # 10 years validity
    builder = builder.serial_number(x509.random_serial_number())
    builder = builder.public_key(ca.public_key())
    builder = builder.add_extension(
        x509.BasicConstraints(ca=True, path_length=None), critical=True
    )

    crl_url = "http://127.0.0.1:8000/get_crl?crl_name=crl.pem"
    crl_extension = CRLDistributionPoints([
        DistributionPoint(
            full_name=[x509.UniformResourceIdentifier(crl_url)],
            relative_name=None,
            crl_issuer=None,
            reasons=None
        )
    ])

    ca_issuers_url = "http://127.0.0.1:8000/get_issuer_cert?crt_name=ca.pem"
    aia_extension = x509.AuthorityInformationAccess([
        x509.AccessDescription(
            x509.AuthorityInformationAccessOID.CA_ISSUERS,
            x509.UniformResourceIdentifier(ca_issuers_url)
        )
    ])

    builder = builder.add_extension(crl_extension, critical=False)
    builder = builder.add_extension(aia_extension, critical=False)

    root_ca_certificate = builder.sign(
        private_key=ca,
        algorithm=hashes.SHA256()
    )

    root_ca_pem = root_ca_certificate.public_bytes(serialization.Encoding.PEM)
    with open("root_ca_certificate.pem", "wb") as file:
        file.write(root_ca_pem)

    private_key_pem = ca.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.TraditionalOpenSSL,
        encryption_algorithm=serialization.NoEncryption()
    )
    with open("root_ca_private_key.pem", "wb") as file:
        file.write(private_key_pem)

