"! <p class="shorttext synchronized">Vía de pago del receptor alternativo (DMEE ZCGI_CT)</p>
"! Determina la vía de pago a usar en el árbol DMEE ZCGI_CT a partir del
"! receptor de pago alternativo del tercero. Lee solo vistas CDS liberadas
"! (I_Supplier / I_SupplierCompany) y guarda el resultado en buffer por
"! proveedor + sociedad para no repetir lecturas en la misma corrida.
CLASS zcl_dmee_via_receptor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Devuelve la vía de pago del receptor alternativo.
    "! Si el tercero no tiene receptor, o el receptor no tiene vías,
    "! devuelve la vía original (iv_rzawe).
    "! @parameter iv_supplier | Tercero (proveedor de la propuesta)
    "! @parameter iv_bukrs    | Sociedad pagadora
    "! @parameter iv_rzawe    | Vía de pago original (FPAYH-RZAWE)
    "! @parameter rv_via      | Vía de pago a usar en el árbol
    CLASS-METHODS get_via
      IMPORTING iv_supplier   TYPE lifnr
                iv_bukrs      TYPE bukrs
                iv_rzawe      TYPE dzlsch
      RETURNING VALUE(rv_via) TYPE dzlsch.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_buf,
             supplier TYPE lifnr,
             bukrs    TYPE bukrs,
             via      TYPE dzlsch,
           END OF ty_buf.

    CLASS-DATA gt_buf TYPE HASHED TABLE OF ty_buf
                      WITH UNIQUE KEY supplier bukrs.
ENDCLASS.


CLASS zcl_dmee_via_receptor IMPLEMENTATION.

  METHOD get_via.
    DATA: lv_payee   TYPE lifnr,
          lv_methods TYPE dzwels.

    " Por defecto: vía de pago del tercero
    rv_via = iv_rzawe.

    CHECK iv_supplier IS NOT INITIAL.

    " Buffer: misma corrida, mismo proveedor/sociedad
    READ TABLE gt_buf INTO DATA(ls_buf)
         WITH TABLE KEY supplier = iv_supplier
                        bukrs    = iv_bukrs.
    IF sy-subrc = 0.
      rv_via = ls_buf-via.
      RETURN.
    ENDIF.

    " 1. Receptor alternativo a nivel sociedad (antes LFB1-LNRZB)
    SELECT SINGLE AlternativePayee
      FROM I_SupplierCompany
      WHERE Supplier    = @iv_supplier
        AND CompanyCode = @iv_bukrs
      INTO @lv_payee.

    " 2. Si no hay, receptor alternativo a nivel general (antes LFA1-LNRZA)
    IF lv_payee IS INITIAL.
      SELECT SINGLE AlternativePayeeAccountNumber
        FROM I_Supplier
        WHERE Supplier = @iv_supplier
        INTO @lv_payee.
    ENDIF.

    " 3. Vías de pago del receptor en la sociedad (antes LFB1-ZWELS)
    IF lv_payee IS NOT INITIAL.
      SELECT SINGLE PaymentMethodsList
        FROM I_SupplierCompany
        WHERE Supplier    = @lv_payee
          AND CompanyCode = @iv_bukrs
        INTO @lv_methods.

      IF lv_methods IS NOT INITIAL.
        " TODO: confirmar regla con funcional si el receptor tiene varias vías
        rv_via = lv_methods(1).
      ENDIF.
    ENDIF.

    INSERT VALUE #( supplier = iv_supplier
                    bukrs    = iv_bukrs
                    via      = rv_via ) INTO TABLE gt_buf.
  ENDMETHOD.

ENDCLASS.
