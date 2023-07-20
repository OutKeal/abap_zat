FUNCTION zat_check_value.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     REFERENCE(LINE) OPTIONAL
*"  TABLES
*"      TAB OPTIONAL
*"      RULE STRUCTURE  ZATS_CHECK_RULE
*"      RET STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  FIELD-SYMBOLS: <fs_value> TYPE ANY.
  FIELD-SYMBOLS: <fs_tab> TYPE  STANDARD TABLE.
  DATA tabix TYPE sy-tabix.
  DATA msg TYPE char40.
  DATA: lt_dd04vv LIKE TABLE OF dd04vv WITH HEADER LINE.
  DATA: lt_doma_value LIKE TABLE OF zats_doma_value WITH HEADER LINE.

  IF LINE IS INITIAL AND tab IS INITIAL.
    RETURN.
  ENDIF.

  lt_dd04vv[] = CORRESPONDING #( rule[] ).
  SORT lt_dd04vv BY rollname.
  DELETE lt_dd04vv WHERE rollname = ''.
  DELETE ADJACENT DUPLICATES FROM lt_dd04vv COMPARING rollname.


  IF lt_dd04vv[] IS NOT INITIAL.

    CALL FUNCTION 'ZAT_DOMA_GET'
*   EXPORTING
*     SPRAS            = '1'
    TABLES
      dd04vv     = lt_dd04vv
*       DD04T      =
      doma_value = lt_doma_value.
  ENDIF.


  SORT lt_doma_value BY rollname domval.

  IF LINE IS NOT INITIAL.
    LOOP AT rule.
      ASSIGN COMPONENT rule-fieldname OF STRUCTURE LINE TO <fs_value>.
      CHECK sy-subrc EQ 0.
      IF <fs_value> IS INITIAL AND rule-notnull = 'X'.
        PERFORM add_msg TABLES ret USING 'E' 002 rule-ddtext '' . "字段&1不能为空
        CONTINUE.
      ENDIF.

      IF rule-rollname IS NOT INITIAL.
        READ TABLE lt_doma_value WITH KEY rollname = rule-rollname
        domval = <fs_value> BINARY SEARCH.
        IF sy-subrc NE 0.
          PERFORM add_msg TABLES ret USING 'E' 003  rule-ddtext <fs_value> ."&1字段值&2不正确
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.


  IF tab IS NOT INITIAL.
    LOOP AT tab .
      tabix = sy-tabix.
      LOOP AT rule.
        ASSIGN COMPONENT rule-fieldname OF STRUCTURE tab TO <fs_value>.
        CHECK sy-subrc EQ 0.
        IF <fs_value> IS INITIAL AND rule-notnull = 'X'.
          PERFORM add_msg TABLES ret USING 'E' 002 tabix rule-ddtext .
          CONTINUE.
        ENDIF.

        IF rule-rollname IS NOT INITIAL.
          READ TABLE lt_doma_value WITH KEY rollname = rule-rollname
          domval = <fs_value> BINARY SEARCH.
          IF sy-subrc NE 0.
            PERFORM add_msg TABLES ret USING 'E' 003 rule-fieldname <fs_value>.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDIF.
ENDFUNCTION.

FORM add_msg TABLES ret STRUCTURE bapiret2
USING TYPE NUMBER fieldname VALUE .

  CONDENSE fieldname NO-GAPS.
  MESSAGE ID 'ZAT'  TYPE TYPE  NUMBER NUMBER
  INTO DATA(l_msg)
        WITH fieldname VALUE.

  APPEND VALUE #( TYPE = TYPE
  NUMBER = NUMBER
  ID = 'ZAT'
  FIELD = fieldname
  message_v1 = fieldname
  message_v2 = VALUE
  ) TO ret.

ENDFORM.
