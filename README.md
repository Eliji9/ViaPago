# ViaPago

Ajuste al árbol DMEE **ZCGI_CT** para que los nodos de `CdtrAcct > Id` se condicionen por la **vía de pago del receptor alternativo** del tercero, en lugar de la vía de pago del tercero (`FPAYH-RZAWE`).

## Objetos

| Objeto | Tipo | Descripción |
|---|---|---|
| `ZCL_DMEE_VIA_RECEPTOR` | Clase | Lógica central: busca el receptor alternativo y su vía de pago. Lee `I_SupplierCompany` e `I_Supplier`, con buffer por proveedor + sociedad. |
| `Z_DMEE_EXIT_VIA_RECEPTOR` | Módulo de funciones | Exit del nodo técnico `RecepPago`. Llama a la clase y devuelve la vía en `C_VALUE`. |
| `ZDMEE_EXIT_AJU_CTA` | Módulo de funciones (existente) | Exit del subnodo `Othr > Id`. Ver cambios en `src/zdmee_exit_aju_cta_cambios.abap`. |

Mapeo de campos de tabla a vistas CDS:

| Antes | Vista | Campo |
|---|---|---|
| `LFB1-LNRZB` | `I_SupplierCompany` | `AlternativePayee` |
| `LFA1-LNRZA` | `I_Supplier` | `AlternativePayeeAccountNumber` |
| `LFB1-ZWELS` | `I_SupplierCompany` | `PaymentMethodsList` |

## Cambios en el árbol ZCGI_CT (DMEEX)

1. **Nodo técnico `RecepPago`** (primer hijo de `CdtrAcct`, antes de `Id`):
   - Tipo elemento, nodo técnico, longitud 1, carácter.
   - ID de referencia: `VIAPAGORECEP`.
   - Procedimiento de asignación: módulo exit → `Z_DMEE_EXIT_VIA_RECEPTOR`.
2. **Nodos `IBAN`** (los 6): en *Condición marco*, primera fila:
   - Antes: `2 | FPAYH | RZAWE | = | 1 | 'I'`
   - Después: `3 | VIAPAGORECEP | | = | 1 | 'I'`
   - La fila de país (`FPAYH-ZBNKS`) no cambia.
3. **Nodo `Othr`**: su condición es solo por país, no cambia. La vía se evalúa dentro de `ZDMEE_EXIT_AJU_CTA`.

## Pendientes

- Confirmar en debug el campo del tercero en `FPAYH` (normalmente `GPA1R`).
- Confirmar con funcional la regla cuando el receptor tiene varias vías en `PaymentMethodsList` (hoy se toma la primera).
- Confirmar nombres de campo de las vistas en el release del sistema.
- Probar con DMEE → Probar o F110 en modo test, con breakpoint en ambos exits.

## Nota Clean Core

Las lecturas de datos usan solo vistas CDS liberadas. Los exits DMEE siguen siendo módulos de funciones clásicos (interfaz `DMEE_EXIT_TEMPLATE`), que no tienen sucesor liberado, por lo que no pueden tener versión de lenguaje *ABAP for Cloud Development*.
