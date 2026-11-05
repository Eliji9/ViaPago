"! <p class="shorttext synchronized">Receptor alternativo y su vía de pago (DMEE ZCGI_CT)</p>
"! Determina, para el tercero de la propuesta de pago, su receptor de pago
"! alternativo y la vía de pago de ese receptor. Lee solo vistas CDS
"! liberadas (I_Supplier / I_SupplierCompany) y guarda el resultado en
"! buffer por proveedor + sociedad para no repetir lecturas en la corrida.
CLASS zcl_dmee_via_receptor DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Vía de pago a usar en el árbol.
    "! Sin receptor, o receptor sin vías: devuelve iv_rzawe.
    "! @parameter iv_supplier | Tercero (proveedor de la propuesta)
    "! @parameter iv_bukrs    | Sociedad pagadora
    "! @parameter iv_rzawe    | Vía de pago original (FPAYH-RZAWE)
    "! @parameter rv_via      | Vía de pago del receptor o la original
    CLASS-METHODS get_via
      IMPORTING iv_supplier   TYPE lifnr
                iv_bukrs      TYPE bukrs
                iv_rzawe      TYPE dzlsch
      RETURNING VALUE(rv_via) TYPE dzlsch.

    "! Partner del que se toman los datos bancarios.
    "! Con receptor alternativo: el receptor. Sin receptor: el tercero.
    "! @parameter iv_supplier | Tercero (proveedor de la propuesta)
    "! @parameter iv_bukrs    | Sociedad pagadora
    "! @parameter rv_partner  | Receptor alternativo o el mismo tercero
    CLASS-METHODS get_payee
      IMPORTING iv_supplier       TYPE lifnr
                iv_bukrs          TYPE bukrs
      RETURNING VALUE(rv_partner) TYPE lifnr.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_buf,
             supplier TYPE lifnr,
             bukrs    TYPE bukrs,
             payee    TYPE lifnr,    " Vacío si no hay receptor alternativo
             methods  TYPE dzwels,   " Vías de pago del receptor
           END OF ty_buf.

    CLASS-DATA gt_buf TYPE HASHED TABLE OF ty_buf
                      WITH UNIQUE KEY supplier bukrs.

    CLASS-METHODS read
      IMPORTING iv_supplier   TYPE lifnr
                iv_bukrs      TYPE bukrs
      RETURNING VALUE(rs_buf) TYPE ty_buf.
ENDCLASS.


CLASS zcl_dmee_via_receptor IMPLEMENTATION.

  METHOD get_via.
    rv_via = iv_rzawe.                       " Por defecto: vía del tercero
    CHECK iv_supplier IS NOT INITIAL.

    DATA(ls_buf) = read( iv_supplier = iv_supplier
                         iv_bukrs    = iv_bukrs ).

    IF ls_buf-methods IS NOT INITIAL.
      " TODO: confirmar regla con funcional si el receptor tiene varias vías
      rv_via = ls_buf-methods(1).
    ENDIF.
  ENDMETHOD.


  METHOD get_payee.
    rv_partner = iv_supplier.                " Por defecto: el tercero
    CHECK iv_supplier IS NOT INITIAL.

    DATA(ls_buf) = read( iv_supplier = iv_supplier
                         iv_bukrs    = iv_bukrs ).

    IF ls_buf-payee IS NOT INITIAL.
      rv_partner = ls_buf-payee.
    ENDIF.
  ENDMETHOD.


  METHOD read.
    " Buffer: misma corrida, mismo proveedor/sociedad
    READ TABLE gt_buf INTO rs_buf
         WITH TABLE KEY supplier = iv_supplier
                        bukrs    = iv_bukrs.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    rs_buf-supplier = iv_supplier.
    rs_buf-bukrs    = iv_bukrs.

    " 1. Receptor alternativo a nivel sociedad (antes LFB1-LNRZB)
    SELECT SINGLE AlternativePayee
      FROM I_SupplierCompany
      WHERE Supplier    = @iv_supplier
        AND CompanyCode = @iv_bukrs
      INTO @rs_buf-payee.

    " 2. Si no hay, receptor alternativo a nivel general (antes LFA1-LNRZA)
    IF rs_buf-payee IS INITIAL.
      SELECT SINGLE AlternativePayeeAccountNumber
        FROM I_Supplier
        WHERE Supplier = @iv_supplier
        INTO @rs_buf-payee.
    ENDIF.

    " 3. Vías de pago del receptor en la sociedad (antes LFB1-ZWELS)
    IF rs_buf-payee IS NOT INITIAL.
      SELECT SINGLE PaymentMethodsList
        FROM I_SupplierCompany
        WHERE Supplier    = @rs_buf-payee
          AND CompanyCode = @iv_bukrs
        INTO @rs_buf-methods.
    ENDIF.

    INSERT rs_buf INTO TABLE gt_buf.
  ENDMETHOD.

ENDCLASS.
