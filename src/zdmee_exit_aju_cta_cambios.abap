*----------------------------------------------------------------------
* Cambios a aplicar en ZDMEE_EXIT_AJU_CTA (exit del nodo Othr > Id)
* No es el FM completo: solo los fragmentos que cambian.
*----------------------------------------------------------------------

* 1. Después del SELECT SINGLE a I_PaymentProposalItem / I_CompanyCode
*    (INTO @DATA(ls_pay)), obtener la vía del receptor:

  DATA(lv_via) = zcl_dmee_via_receptor=>get_via(
                   iv_supplier = |{ ls_pay-supplier ALPHA = IN }|
                   iv_bukrs    = ls_pay-companycode
                   iv_rzawe    = gs_item-fpayh-rzawe ).

* 2. Reemplazar todas las apariciones de gs_item-fpayh-rzawe en los IF
*    por lv_via.

* 3. Corregir la condición del bloque "IF c_value IS INITIAL" (línea ~83).
*    ANTES (siempre verdadera, ninguna vía es 'I' y 'J' a la vez):
*
*      IF NOT gs_item-fpayh-rzawe = 'I' OR NOT gs_item-fpayh-rzawe = 'J'.
*
*    DESPUÉS (ni internacional ni tarjeta):

    IF lv_via <> 'I' AND lv_via <> 'J'.   " pago internacional I y tarjeta J
