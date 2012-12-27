/*
 * Copyright © 2012 Routek S.L.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *	Agustí Moll i Garcia
 *	Simó Albert i Beltran
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/rsa.h>
#include <openssl/err.h>


int do_evp_unseal(FILE *rsa_pkey_file, FILE *in_file, FILE *out_file)
{
    int retval = 0;
    RSA *rsa_pkey = NULL;
    EVP_PKEY *pkey = EVP_PKEY_new();
    EVP_CIPHER_CTX ctx;
    unsigned char buffer[4096];
    unsigned char buffer_out[4096 + EVP_MAX_IV_LENGTH];
    size_t len;
    int len_out;
    unsigned char *ek;
    unsigned int eklen;
    uint32_t eklen_n;
    unsigned char iv[EVP_MAX_IV_LENGTH];

    if (!PEM_read_RSAPrivateKey(rsa_pkey_file, &rsa_pkey, NULL, NULL))
    {
        fprintf(stderr, "PEM_read_RSAPrivateKey.\n");
        ERR_print_errors_fp(stderr);
	return(2);
    }

    if (!EVP_PKEY_assign_RSA(pkey, rsa_pkey))
    {
        fprintf(stderr, "EVP_PKEY_assign_RSA: ha fallat.\n");
	return(3);
    }

    EVP_CIPHER_CTX_init(&ctx);
    ek = malloc(EVP_PKEY_size(pkey));

    if (fread(&eklen_n, sizeof eklen_n, 1, in_file) != 1)
    {
        perror("Error al llegir fitxer.\n");
        retval = 4;
        goto out_free;
    }
    eklen = ntohl(eklen_n);
    if (eklen > EVP_PKEY_size(pkey))
    {
        fprintf(stderr, "Error en la longitut de la clau (%u > %d)\n", eklen,
            EVP_PKEY_size(pkey));
        retval = 4;
        goto out_free;
    }
    if (fread(ek, eklen, 1, in_file) != 1)
    {
        perror("Error al llegir fitxer.\n");
        retval = 4;
        goto out_free;
    }
    if (fread(iv, EVP_CIPHER_iv_length(EVP_aes_128_cbc()), 1, in_file) != 1)
    {
        perror("Error al llegir fitxer.\n");
        retval = 4;
        goto out_free;
    }

    if (!EVP_OpenInit(&ctx, EVP_aes_128_cbc(), ek, eklen, iv, pkey))
    {
        fprintf(stderr, "EVP_OpenInit: ha fallat.\n");
        retval = 3;
        goto out_free;
    }

    while ((len = fread(buffer, 1, sizeof buffer, in_file)) > 0)
    {
        if (!EVP_OpenUpdate(&ctx, buffer_out, &len_out, buffer, len))
        {
            fprintf(stderr, "EVP_OpenUpdate: ha fallat.\n");
            retval = 3;
            goto out_free;
        }

        if (fwrite(buffer_out, len_out, 1, out_file) != 1)
        {
            perror("Error al escriure el fitxer.\n");
            retval = 5;
            goto out_free;
        }
    }

    if (ferror(in_file))
    {
        perror("Error al escriure el fitxer.\n");
        retval = 4;
        goto out_free;
    }

    if (!EVP_OpenFinal(&ctx, buffer_out, &len_out))
    {
        fprintf(stderr, "EVP_SealFinal: ha fallat.\n");
        retval = 3;
        goto out_free;
    }

    if (len_out && fwrite(buffer_out, len_out, 1, out_file) != 1)
    {
        perror("Error al escriure el fitxer.\n");
        retval = 5;
        goto out_free;
    }

    out_free:
    EVP_PKEY_free(pkey);
    free(ek);
    return retval;
}

int main(int argc, char *argv[])
{
    FILE *rsa_pkey_file;
    int rv;

    if (argc < 2)
    {
        fprintf(stderr, "Us: %s <RSA Private Key File>\n", argv[0]);
        exit(1);
    }

    rsa_pkey_file = fopen(argv[1], "rb");
    if (!rsa_pkey_file)
    {
        perror(argv[1]);
        fprintf(stderr, "Error al llegir la clau privada.\n");
        exit(2);
    }

    rv = do_evp_unseal(rsa_pkey_file, stdin, stdout);

    fclose(rsa_pkey_file);
    return rv;
}
