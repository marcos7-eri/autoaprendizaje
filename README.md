# Autoaprendizaje 1: OCI con Terraform y GitHub Actions

Implementación del flujo mostrado en el [video de Cloud Quick Labs](https://www.youtube.com/watch?v=3rmROBpBu9A): un repositorio GitHub ejecuta Terraform para crear un compartment, una VCN, subred pública, internet gateway, tabla de rutas, lista de seguridad y una VM en Oracle Cloud Infrastructure (OCI).

El [repositorio del video](https://github.com/RekhuGopal/OracleCloudInfrastructure) sirve como referencia. Esta versión activa los recursos que allí quedaron comentados, elimina los OCID y la clave SSH de la cuenta del autor, fija las versiones y usa el [backend nativo de OCI](https://developer.hashicorp.com/terraform/language/backend/oci), que admite bloqueo del estado. El estado se guarda en Object Storage y la clave API se configura como secreto de GitHub.

## Requisitos previos

1. Una cuenta OCI con permiso para crear un compartment y los recursos de red y cómputo dentro de él. El usuario de automatización también necesita acceso al bucket de estado para leer, crear y borrar objetos (incluido el archivo de bloqueo).
2. Un bucket de Object Storage **ya creado**, preferiblemente con versionado activado. Anota su nombre y el namespace de Object Storage. El workflow crea el objeto de estado automáticamente en `autoaprendizaje1/terraform.tfstate`.
3. Una clave API OCI: registra la **clave pública API** en el perfil del usuario de OCI; conserva su PEM privada para el secreto `OCI_PRIVATE_KEY`. Esta clave API es distinta de la clave SSH de acceso a la VM.
4. Una clave SSH propia. Se usa solo su parte pública en `OCI_SSH_PUBLIC_KEY`. El CIDR `OCI_SSH_SOURCE_CIDR` debe limitar el puerto 22 a tu IP pública (`x.x.x.x/32`).
5. Una imagen OCI compatible con la región y el shape. El workflow usa Oracle Linux 8.10 ARM en São Paulo y `VM.Standard.A1.Flex` con 1 OCPU y 2 GB; verifica la disponibilidad y los límites Always Free de tu tenancy antes de aplicar.
6. Un repositorio GitHub propio para publicar estos archivos. Terraform CLI `>= 1.12, < 1.17` para uso local.

## Configuración de GitHub Actions

En **Settings → Secrets and variables → Actions → Repository secrets** del repositorio propio, crea:

| Secreto | Valor |
| --- | --- |
| `OCI_USER_OCID` | OCID del usuario cuya clave API se registró. |
| `OCI_TENANCY_OCID` | OCID del tenancy. |
| `OCI_FINGERPRINT` | Fingerprint de la clave API registrada. |
| `OCI_REGION` | Identificador de región, por ejemplo `us-ashburn-1`. |
| `OCI_PRIVATE_KEY` | Contenido completo del PEM **privado** de la clave API. |
| `OCI_STATE_BUCKET` | Nombre del bucket del estado. |
| `OCI_STATE_NAMESPACE` | Namespace de Object Storage. |
| `OCI_PARENT_COMPARTMENT_OCID` | OCID del tenancy o compartment padre. |
| `OCI_SSH_PUBLIC_KEY` | Una línea de clave **pública** SSH. |
| `OCI_SSH_SOURCE_CIDR` | IP autorizada para SSH, por ejemplo `203.0.113.10/32`. |

No subas PEM privados, `terraform.tfvars`, archivos `.tfstate` ni planes al repositorio. Si usas una clave API con frase de paso, esta configuración debe ampliarse para proporcionarla de forma segura; actualmente espera una clave sin frase de paso.

El secreto `OCI_IMAGE_OCID` creado para la imagen x86 original ya no se usa en el workflow A1; puedes conservarlo para volver a E2 en el futuro.

La configuración de la VM usa el primer availability domain devuelto por OCI. Tras errores de capacidad al crear `VM.Standard.E2.1.Micro` y A1 Flex de 6 GB en São Paulo, el workflow usa `VM.Standard.A1.Flex` con 1 OCPU y 2 GB de RAM, más una imagen ARM de Oracle Linux 8.10 para `sa-saopaulo-1`. El shape y la imagen se fijan en `.github/workflows/oci.yml`; ajusta ambos al cambiar de región o arquitectura. La configuración de memoria en `Terraform/main.tf` se aplica solo a A1 Flex. La disponibilidad de host sigue dependiendo de OCI.

## Despliegue desde GitHub

1. Publica este directorio en tu repositorio GitHub, manteniendo `.github/workflows/oci.yml` en la raíz. Si el repositorio remoto está vacío, desde esta carpeta puedes ejecutar:

   ```powershell
   git init -b main
   git add .
   git commit -m "Configurar OCI con Terraform"
   git remote add origin https://github.com/TU_USUARIO/TU_REPOSITORIO.git
   git push -u origin main
   ```

   Git requiere que tu nombre y correo de autor estén configurados para crear el commit. Sustituye la URL por la de tu repositorio propio.
2. Abre **Actions → OCI con Terraform → Run workflow** y elige `plan`. Revisa la creación prevista.
3. Ejecuta el mismo workflow con `apply`. El job reutiliza el plan generado en esa misma ejecución y aplica los recursos.
4. En OCI, verifica el compartment `autoaprendizaje1`, la VCN y la VM. La IP pública también aparece como output de Terraform en el estado.

El workflow es manual y serializa las ejecuciones sobre el mismo estado. No ejecuta `destroy`. Para cambiar configuraciones después del primer despliegue, modifica variables y ejecuta `plan` antes de `apply`.

## Verificación local

En PowerShell, configura `~/.oci/config` con un perfil `DEFAULT` válido y su clave API, crea `Terraform/terraform.tfvars` a partir de `Terraform/terraform.tfvars.example` con tus valores, y luego ejecuta desde `Terraform`:

```powershell
terraform init -backend-config="bucket=NOMBRE_DEL_BUCKET" -backend-config="namespace=NAMESPACE"
terraform fmt -check
terraform validate
terraform plan
```

Para aplicar localmente, revisa primero el plan y después ejecuta `terraform apply`. La configuración del backend se guarda bajo `.terraform/`; ese directorio está ignorado por Git.

## Referencias

- [Tutorial en video](https://www.youtube.com/watch?v=3rmROBpBu9A)
- [Repositorio original](https://github.com/RekhuGopal/OracleCloudInfrastructure)
- [Estado en Object Storage con backend OCI](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/object-storage-state.htm)
- [Autenticación del proveedor OCI](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/configuring.htm)
- [Secretos de GitHub Actions](https://docs.github.com/en/actions/concepts/security/secrets)

