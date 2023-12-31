FUNCTION zat_create_idoc_input.
*"--------------------------------------------------------------------
*"*"局部接口：
*"  IMPORTING
*"     VALUE(INPUT_METHOD) LIKE  BDWFAP_PAR-INPUTMETHD
*"     VALUE(MASS_PROCESSING) LIKE  BDWFAP_PAR-MASS_PROC
*"  EXPORTING
*"     VALUE(WORKFLOW_RESULT) LIKE  BDWF_PARAM-RESULT
*"     VALUE(APPLICATION_VARIABLE) LIKE  BDWF_PARAM-APPL_VAR
*"     VALUE(IN_UPDATE_TASK) LIKE  BDWFAP_PAR-UPDATETASK
*"     VALUE(CALL_TRANSACTION_DONE) LIKE  BDWFAP_PAR-CALLTRANS
*"  TABLES
*"      IDOC_CONTRL STRUCTURE  EDIDC
*"      IDOC_DATA STRUCTURE  EDIDD
*"      IDOC_STATUS STRUCTURE  BDIDOCSTAT
*"      RETURN_VARIABLES STRUCTURE  BDWFRETVAR
*"      SERIALIZATION_INFO STRUCTURE  BDI_SER
*"  EXCEPTIONS
*"      WRONG_FUNCTION_CALLED
*"--------------------------------------------------------------------
*----------------------------------------------------------------------*
*  this function module is generated                                   *
*          never change it manually, please!        2023.05.12         *
*----------------------------------------------------------------------*

  DATA:
        z1zats_bapi_head LIKE z1zats_bapi_head,
        z1zats_bapi_item LIKE z1zats_bapi_item,

        e_atno           LIKE
        zatt_head-atno,
        e_status         LIKE
        zatt_head-status,
        is_head          LIKE
        zats_bapi_head,

        it_item          LIKE zats_bapi_item
        OCCURS 0 WITH HEADER LINE,
        et_return        LIKE bapiret2
        OCCURS 0 WITH HEADER LINE,

        t_edidd          LIKE edidd OCCURS 0 WITH HEADER LINE,
        bapi_retn_info   LIKE bapiret2 OCCURS 0 WITH HEADER LINE.

  DATA: error_flag,
        bapi_idoc_status LIKE bdidocstat-status.

  in_update_task = 'X'.
  CLEAR call_transaction_done.
* check if the function is called correctly                            *
  READ TABLE idoc_contrl INDEX 1.
  IF sy-subrc <> 0.
    EXIT.
ELSEIF idoc_contrl-mestyp <> 'ZATCREATE'.
    RAISE wrong_function_called.
  ENDIF.

* go through all IDocs                                                 *
  LOOP AT idoc_contrl.
*   select segments belonging to one IDoc                              *
    REFRESH t_edidd.
    LOOP AT idoc_data WHERE docnum = idoc_contrl-docnum.
      APPEND idoc_data TO t_edidd.
    ENDLOOP.

*   through all segments of this IDoc                                  *
    CLEAR error_flag.
    REFRESH bapi_retn_info.
    CATCH SYSTEM-EXCEPTIONS conversion_errors = 1.
    LOOP AT t_edidd INTO idoc_data.

      CASE idoc_data-segnam.

      WHEN 'Z1ZATS_BAPI_HEAD'.

        z1zats_bapi_head = idoc_data-sdata.
        MOVE-CORRESPONDING z1zats_bapi_head
        TO is_head.                                  "#EC ENHOK

        IF z1zats_bapi_head-budat
        IS INITIAL.
          CLEAR is_head-budat.
        ENDIF.

      WHEN 'Z1ZATS_BAPI_ITEM'.

        z1zats_bapi_item = idoc_data-sdata.
        MOVE-CORRESPONDING z1zats_bapi_item
        TO it_item.                                  "#EC ENHOK

        APPEND it_item.

      ENDCASE.

    ENDLOOP.
    ENDCATCH.
    IF sy-subrc = 1.
*     write IDoc status-record as error and continue                   *
      CLEAR bapi_retn_info.
      bapi_retn_info-TYPE   = 'E'.
      bapi_retn_info-ID     = 'B1'.
      bapi_retn_info-NUMBER = '527'.
      bapi_retn_info-message_v1 = idoc_data-segnam.
      bapi_idoc_status      = '51'.
      PERFORM zat_create_idoc_status
      TABLES t_edidd
        idoc_status
        return_variables
      USING idoc_contrl
            bapi_retn_info
            bapi_idoc_status
            workflow_result.
      CONTINUE.
    ENDIF.
*   call BAPI-function in this system
    SELECT
    SINGLE *
    INTO @DATA(ls_head)
          FROM zatt_head
          WHERE docnum = @idoc_contrl-docnum.
    IF sy-subrc NE 0.

      is_head-docnum = idoc_contrl-docnum.
      CALL FUNCTION 'ZAT_CREATE'
      EXPORTING
        is_head   = is_head
      IMPORTING
        e_atno    = e_atno
        e_status  = e_status
      TABLES
        it_item   = it_item
        et_return = et_return
      EXCEPTIONS
        OTHERS    = 1.
    ELSE.
      e_atno = ls_head-atno.
      CALL FUNCTION 'ZAT_POST'
      EXPORTING
        iv_type   = ls_head-TYPE
        iv_atno   = ls_head-atno
        iv_budat  = ls_head-budat
      IMPORTING
        e_status  = e_status
      TABLES
        et_return = et_return.


    ENDIF.
    IF sy-subrc <> 0.
*     write IDoc status-record as error                                *
      CLEAR bapi_retn_info.
      bapi_retn_info-TYPE       = 'E'.
      bapi_retn_info-ID         = sy-msgid.
      bapi_retn_info-NUMBER     = sy-msgno.
      bapi_retn_info-message_v1 = sy-msgv1.
      bapi_retn_info-message_v2 = sy-msgv2.
      bapi_retn_info-message_v3 = sy-msgv3.
      bapi_retn_info-message_v4 = sy-msgv4.
      bapi_idoc_status          = '51'.
      PERFORM zat_create_idoc_status
      TABLES t_edidd
        idoc_status
        return_variables
      USING idoc_contrl
            bapi_retn_info
            bapi_idoc_status
            workflow_result.
    ELSE.
      LOOP AT et_return.
        IF NOT et_return IS INITIAL.
          CLEAR bapi_retn_info.
          MOVE-CORRESPONDING et_return
          TO bapi_retn_info.                           "#EC ENHOK
          IF et_return-TYPE = 'A' OR
          et_return-TYPE = 'E'.
            error_flag = 'X'.
          ENDIF.
          APPEND bapi_retn_info.
        ENDIF.
      ENDLOOP.
      LOOP AT bapi_retn_info.
*       write IDoc status-record                                       *
        IF error_flag IS INITIAL.
          bapi_idoc_status = '53'.
        ELSE.
          bapi_idoc_status = '51'.
          IF bapi_retn_info-TYPE = 'S'.
            CONTINUE.
          ENDIF.
        ENDIF.
        PERFORM zat_create_idoc_status
        TABLES t_edidd
          idoc_status
          return_variables
        USING idoc_contrl
              bapi_retn_info
              bapi_idoc_status
              workflow_result.
      ENDLOOP.
      IF sy-subrc <> 0.
*      'ET_RETURN'                                                     *
*       is empty write idoc status-record as successful                *
        CLEAR bapi_retn_info.
        bapi_retn_info-TYPE       = 'S'.
        bapi_retn_info-ID         = 'B1'.
        bapi_retn_info-NUMBER     = '501'.
        bapi_retn_info-message_v1 = 'ZATCREATE'.
        bapi_idoc_status          = '53'.
        PERFORM zat_create_idoc_status
        TABLES t_edidd
          idoc_status
          return_variables
        USING idoc_contrl
              bapi_retn_info
              bapi_idoc_status
              workflow_result.
      ENDIF.
      IF error_flag IS INITIAL.
*       write linked object keys                                       *
        CLEAR return_variables.
        return_variables-wf_param = 'Appl_Objects'.
        return_variables-doc_number = e_atno.
        APPEND return_variables.
      ENDIF.
    ENDIF.
  ENDLOOP.                             " idoc_contrl

ENDFUNCTION.


* subroutine writing IDoc status-record                                *
FORM zat_create_idoc_status
TABLES idoc_data    STRUCTURE  edidd
  idoc_status  STRUCTURE  bdidocstat
  r_variables  STRUCTURE  bdwfretvar
USING idoc_contrl  LIKE  edidc
      VALUE(retn_info) LIKE   bapiret2
      status       LIKE  bdidocstat-status
      wf_result    LIKE  bdwf_param-result.

  CLEAR idoc_status.
  idoc_status-docnum   = idoc_contrl-docnum.
  idoc_status-msgty    = retn_info-TYPE.
  idoc_status-msgid    = retn_info-ID.
  idoc_status-msgno    = retn_info-NUMBER.
  idoc_status-appl_log = retn_info-log_no.
  idoc_status-msgv1    = retn_info-message_v1.
  idoc_status-msgv2    = retn_info-message_v2.
  idoc_status-msgv3    = retn_info-message_v3.
  idoc_status-msgv4    = retn_info-message_v4.
  idoc_status-repid    = sy-repid.
  idoc_status-status   = status.

  CASE retn_info-PARAMETER.
  WHEN 'ISHEAD'
    OR 'IS_HEAD'
    .
    LOOP AT idoc_data WHERE
    segnam = 'Z1ZATS_BAPI_HEAD'.
      retn_info-row = retn_info-row - 1.
      IF retn_info-row <= 0.
        idoc_status-segnum = idoc_data-segnum.
        idoc_status-segfld = retn_info-FIELD.
        EXIT.
      ENDIF.
    ENDLOOP.
  WHEN 'ITITEM'
    OR 'IT_ITEM'
    .
    LOOP AT idoc_data WHERE
    segnam = 'Z1ZATS_BAPI_ITEM'.
      retn_info-row = retn_info-row - 1.
      IF retn_info-row <= 0.
        idoc_status-segnum = idoc_data-segnum.
        idoc_status-segfld = retn_info-FIELD.
        EXIT.
      ENDIF.
    ENDLOOP.
  WHEN OTHERS.

  ENDCASE.

  INSERT idoc_status INDEX 1.

  IF idoc_status-status = '51'.
    wf_result = '99999'.
    r_variables-wf_param   = 'Error_IDOCs'.
    r_variables-doc_number = idoc_contrl-docnum.
    READ TABLE r_variables FROM r_variables.
    IF sy-subrc <> 0.
      APPEND r_variables.
    ENDIF.
ELSEIF idoc_status-status = '53'.
    CLEAR wf_result.
    r_variables-wf_param = 'Processed_IDOCs'.
    r_variables-doc_number = idoc_contrl-docnum.
    READ TABLE r_variables FROM r_variables.
    IF sy-subrc <> 0.
      APPEND r_variables.
    ENDIF.
    r_variables-wf_param = 'Appl_Object_Type'.
    r_variables-doc_number = 'ZAT'.
    READ TABLE r_variables FROM r_variables.
    IF sy-subrc <> 0.
      APPEND r_variables.
    ENDIF.
  ENDIF.

ENDFORM.                               " ZAT_CREATE_IDOC_STATUS
