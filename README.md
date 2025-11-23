# Gabriel Jaime & Asociados — Proyecto

Cambios realizados para mejorar experiencia móvil y optimización de imágenes.

Qué se implementó:

- Menú hamburguesa responsive y accesible (HTML/CSS/JS).
- `loading="lazy"` añadido a imágenes grandes y alt descriptivos donde faltaban.
- Script PowerShell en `scripts/optimize-images.ps1` para generar versiones optimizadas (WebP y tamaños redimensionados). Requiere `cwebp` y/o ImageMagick (`magick`).

Cómo probar localmente (PowerShell):

```powershell
cd "c:\Users\desarrollo\Downloads\GABRIELJAIME-ASOCIADOS-master"
py -3 -m http.server 8000
# abrir http://localhost:8000 en el navegador y usar modo responsive en DevTools o el teléfono
```

Cómo optimizar imágenes (opcional):

1. Instalar herramientas:
   - ImageMagick (magick) — para redimensionar
   - libwebp (cwebp) — para generar WebP
2. Ejecutar el script (desde la raíz del proyecto):

```powershell
# Ejecutar el script que generará archivos en img/optimized
.
\scripts\optimize-images.ps1
```

Notas:
- El script no sobrescribe archivos existentes; crea una carpeta `img/optimized`.
- Si no tienes `cwebp` o `magick`, el script avisará y saltará los pasos correspondientes.

Siguientes mejoras recomendadas:
- Añadir srcset/picture usando las imágenes generadas (puedo automatizarlo si quieres).
- Optimizar aún más CSS y combinar/minificar para producción.
- Añadir pruebas visuales o CI para validar responsividad.
