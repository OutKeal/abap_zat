class ZCL_IM_AT_MB_DOCUMENT_BADI definition
  public
  final
  create public .

public section.

  interfaces IF_BADI_INTERFACE .
  interfaces IF_EX_MB_DOCUMENT_BADI .
protected section.
private section.
ENDCLASS.



CLASS ZCL_IM_AT_MB_DOCUMENT_BADI IMPLEMENTATION.


  METHOD if_ex_mb_document_badi~mb_document_before_update.

    READ TABLE xmkpf INTO DATA(l_mkpf) INDEX 1.

    CALL FUNCTION 'ZAT_TRAN_MB_DOC'
      EXPORTING
        mblnr = l_mkpf-mblnr
        mjahr = l_mkpf-mjahr.

  ENDMETHOD.


  method IF_EX_MB_DOCUMENT_BADI~MB_DOCUMENT_UPDATE.
  endmethod.
ENDCLASS.
