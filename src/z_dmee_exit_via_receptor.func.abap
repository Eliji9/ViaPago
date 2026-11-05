FUNCTION z_dmee_exit_via_receptor.
*"----------------------------------------------------------------------
*"*"Interfaz local (copiada de DMEE_EXIT_TEMPLATE):
*"  IMPORTING
*"     VALUE(I_TREE_TYPE) TYPE  DMEE_TREETYPE
*"     VALUE(I_TREE_ID)   TYPE  DMEE_TREEID
*"     VALUE(I_ITEM)
*"     VALUE(I_PARAM)
*"     VALUE(I_UPARAM)
*"     REFERENCE(I_EXTENSION) TYPE  DMEE_EXIT_INTERFACE
*"  EXPORTING
*"     REFERENCE(O_VALUE)
*"     REFERENCE(C_VALUE)
*"     REFERENCE(N_VALUE)
*"     REFERENCE(P_VALUE)
*"  TABLES
*"      I_TAB
*"----------------------------------------------------------------------
* Exit del nodo técnico RecepPago (ID ref. VIAPAGORECEP) bajo CdtrAcct,
* árbol DMEE ZCGI_CT. Devuelve la vía de pago del receptor alternativo,
* que usan las condiciones de los nodos IBAN.
*----------------------------------------------------------------------

  DATA ls_item TYPE dmee_paym_if_type.   " FPAYH / FPAYHX / FPAYP

  ls_item = i_item.

  " Validar en debug el campo del tercero (normalmente FPAYH-GPA1R)
  c_value = zcl_dmee_via_receptor=>get_via(
              iv_supplier = |{ ls_item-fpayh-gpa1r ALPHA = IN }|
              iv_bukrs    = ls_item-fpayh-zbukr
              iv_rzawe    = ls_item-fpayh-rzawe ).

ENDFUNCTION.
