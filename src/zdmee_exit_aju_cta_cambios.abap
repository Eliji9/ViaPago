*----------------------------------------------------------------------
* Cambios a aplicar en ZDMEE_EXIT_AJU_CTA (exit del nodo Othr > Id)
* No es el FM completo: solo los fragmentos que cambian.
*----------------------------------------------------------------------

* 1. Después del SELECT SINGLE a I_PaymentProposalItem / I_CompanyCode
*    (INTO @DATA(ls_pay)), obtener el partner bancario y la vía:

  DATA(lv_tercero) = CONV lifnr( |{ ls_pay-supplier ALPHA = IN }| ).

  " Receptor alternativo si existe; si no, el mismo tercero
  DATA(lv_partner) = zcl_dmee_via_receptor=>get_payee(
                       iv_supplier = lv_tercero
                       iv_bukrs    = ls_pay-companycode ).

  DATA(lv_via) = zcl_dmee_via_receptor=>get_via(
                   iv_supplier = lv_tercero
                   iv_bukrs    = ls_pay-companycode
                   iv_rzawe    = gs_item-fpayh-rzawe ).

* 2. Cuenta bancaria: leer la del receptor (lv_partner), no la del tercero.

  SELECT SINGLE bankaccount
    FROM i_businesspartnerbank
    INTO @DATA(lv_cta)
    WHERE businesspartner EQ @lv_partner
      AND bankcountrykey  EQ @ls_pay-country             "país de la sociedad
      AND bankcontrolkey  EQ @ls_pay-paymentcurrency(2). "moneda del pago

* 3. Referencia en ZR_TFI_PROV_REF: usar lv_partner en vez de ls_pay-supplier
*    / lv_supplier (confirmar con funcional que la referencia se registra
*    con el receptor y no con el tercero).

    SELECT SINGLE referencia
      FROM zr_tfi_prov_ref
      INTO @c_value
      WHERE saknr = @c_value
        AND lifnr = @lv_partner
        AND bukrs = @ls_pay-companycode.

* 4. Reemplazar todas las apariciones de gs_item-fpayh-rzawe en los IF
*    por lv_via.

* 5. Corregir la condición del bloque "IF c_value IS INITIAL" (línea ~83).
*    ANTES (siempre verdadera, ninguna vía es 'I' y 'J' a la vez):
*
*      IF NOT gs_item-fpayh-rzawe = 'I' OR NOT gs_item-fpayh-rzawe = 'J'.
*
*    DESPUÉS (ni internacional ni tarjeta):

    IF lv_via <> 'I' AND lv_via <> 'J'.   " pago internacional I y tarjeta J
