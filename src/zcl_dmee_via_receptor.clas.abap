"! <p class="shorttext synchronized">Receptor alternativo y su vía de pago (DMEE ZCGI_CT)</p>
"! Determina, para el tercero de la propuesta de pago, su receptor de pago
"! alternativo y la vía de pago de ese receptor. Lee solo vistas CDS
"! liberadas (I_Supplier / I_SupplierCompany). Sin buffer: cada llamada
"! lee el maestro actual.
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
    "! Receptor alternativo del tercero (vacío si no tiene)
    CLASS-METHODS read_payee
      IMPORTING iv_supplier     TYPE lifnr
                iv_bukrs        TYPE bukrs
      RETURNING VALUE(rv_payee) TYPE lifnr.
ENDCLASS.


CLASS zcl_dmee_via_receptor IMPLEMENTATION.

  METHOD get_via.
    DATA lv_methods TYPE dzwels.

    rv_via = iv_rzawe.                       " Por defecto: vía del tercero
    CHECK iv_supplier IS NOT INITIAL.

    DATA(lv_payee) = read_payee( iv_supplier = iv_supplier
                                 iv_bukrs    = iv_bukrs ).
    CHECK lv_payee IS NOT INITIAL.

    " Vías de pago del receptor en la sociedad (antes LFB1-ZWELS)
    SELECT SINGLE PaymentMethodsList
      FROM I_SupplierCompany
      WHERE Supplier    = @lv_payee
        AND CompanyCode = @iv_bukrs
      INTO @lv_methods.

    IF lv_methods IS NOT INITIAL.
      " TODO: confirmar regla con funcional si el receptor tiene varias vías
      rv_via = lv_methods(1).
    ENDIF.
  ENDMETHOD.


  METHOD get_payee.
    rv_partner = iv_supplier.                " Por defecto: el tercero
    CHECK iv_supplier IS NOT INITIAL.

    DATA(lv_payee) = read_payee( iv_supplier = iv_supplier
                                 iv_bukrs    = iv_bukrs ).
    IF lv_payee IS NOT INITIAL.
      rv_partner = lv_payee.
    ENDIF.
  ENDMETHOD.


  METHOD read_payee.
    " 1. Receptor alternativo a nivel sociedad (antes LFB1-LNRZB)
    SELECT SINGLE AlternativePayee
      FROM I_SupplierCompany
      WHERE Supplier    = @iv_supplier
        AND CompanyCode = @iv_bukrs
      INTO @rv_payee.

    " 2. Si no hay, receptor alternativo a nivel general (antes LFA1-LNRZA)
    IF rv_payee IS INITIAL.
      SELECT SINGLE AlternativePayeeAccountNumber
        FROM I_Supplier
        WHERE Supplier = @iv_supplier
        INTO @rv_payee.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
