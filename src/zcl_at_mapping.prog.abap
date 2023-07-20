*&---------------------------------------------------------------------*
*& Include ZCL_AT_MAPPING
*&---------------------------------------------------------------------*
DEFINE mapping.
  FIELD-SYMBOLS:
  <to_t>   TYPE table,
  <to_tx>  TYPE table,
  <to_s>   TYPE any,
  <to_sx>  TYPE any,
  <to_f>   TYPE any,
  <to_fx>  TYPE any,
  <from_f>  TYPE any.
  DATA:l_step TYPE zatd_step.
DATA:ls_item_step TYPE zatt_item_step.
    DATA:l_docnr TYPE docnr.

  DATA:l_fieldname TYPE char40.

  SORT gt_step_rule BY type step rule_type to_tabname.

  LOOP AT gt_step_rule INTO gs_step_rule
  WHERE step = gs_item_step-step
  GROUP BY ( type = gs_step_rule-type
  step = gs_step_rule-step
  rule_type = gs_step_rule-rule_type
  to_tabname = gs_step_rule-to_tabname
  ) INTO DATA(lt_rule).

    CASE lt_rule-rule_type.
    WHEN 'G'.
      LOOP AT GROUP lt_rule INTO DATA(ls_rule).
        ASSIGN (ls_rule-to_fieldname) TO <to_f>.
        CHECK sy-subrc EQ 0.
        move_value.
      ENDLOOP.
    WHEN 'H'.
      l_fieldname = 'LS_' && lt_rule-to_tabname.
      ASSIGN (l_fieldname) TO <to_s>.
      CHECK sy-subrc EQ 0.
      l_fieldname = 'LS_' && lt_rule-to_tabname && 'X'.
      ASSIGN (l_fieldname) TO <to_sx>.
      LOOP AT GROUP lt_rule INTO ls_rule.
        ASSIGN COMPONENT ls_rule-to_fieldname OF STRUCTURE <to_s> TO <to_f>.
        CHECK sy-subrc EQ 0.
        move_value .
        ASSIGN COMPONENT ls_rule-to_fieldname OF STRUCTURE <to_sx> TO <to_fx>.
        IF sy-subrc EQ 0.
          move_valuex.
        ENDIF.
      ENDLOOP.
    WHEN 'I'.
      l_fieldname = 'LT_' && lt_rule-to_tabname && '[]'.
      ASSIGN (l_fieldname) TO <to_t>.
      CHECK sy-subrc EQ 0.
      l_fieldname = 'LS_' && lt_rule-to_tabname.
      ASSIGN (l_fieldname) TO <to_s>.
      CHECK sy-subrc EQ 0.
      l_fieldname = 'LT_' && lt_rule-to_tabname && 'X[]'.
      ASSIGN (l_fieldname) TO <to_tx>.
      l_fieldname = 'LS_' && lt_rule-to_tabname && 'X'.
      ASSIGN (l_fieldname) TO <to_sx>.

      LOOP AT gt_item INTO gs_item.
        LOOP AT GROUP lt_rule INTO ls_rule.
          ASSIGN COMPONENT ls_rule-to_fieldname  OF STRUCTURE <to_s> TO <to_f>.
          CHECK sy-subrc EQ 0.
          move_value.
          ASSIGN COMPONENT ls_rule-to_fieldname OF STRUCTURE <to_sx> TO <to_fx>.
          IF sy-subrc EQ 0.
            move_valuex.
          ENDIF.
        ENDLOOP.
        IF <to_s> IS ASSIGNED AND <to_t> IS ASSIGNED.
          APPEND <to_s> TO <to_t>.
          CLEAR  <to_s>.
        ENDIF.
        IF <to_sx> IS ASSIGNED AND <to_tx> IS ASSIGNED.
          APPEND <to_sx> TO <to_tx>.
          CLEAR <to_sx>.
        ENDIF.
      ENDLOOP.
    WHEN OTHERS.
    ENDCASE.
  ENDLOOP.
END-OF-DEFINITION.

DEFINE move_value.
  CASE  ls_rule-from_fieldalv.
  WHEN ' '.
    <to_f> = ls_rule-default_value.
  WHEN 'HEAD'.
    ASSIGN COMPONENT ls_rule-from_fname OF STRUCTURE gs_head TO <from_f>.
    IF sy-subrc EQ 0.
      <to_f> = <from_f>.
*      PERFORM fm_zz_move_value USING ls_rule  CHANGING fvalue.
    ENDIF.
  WHEN 'ITEM'.
    ASSIGN COMPONENT ls_rule-from_fname OF STRUCTURE gs_item TO <from_f>.
    IF sy-subrc EQ 0.
      <to_f> = <from_f>.
*      PERFORM fm_zz_move_value USING ls_rule  CHANGING fvalue.
    ENDIF.
  WHEN 'LAST'.

    l_step = ls_rule-from_fname.
    IF l_step IS INITIAL.
      l_step = gs_item_step-step - 1.
    ELSE.
      l_step = l_step.
    ENDIF.
    READ TABLE gt_item_step INTO ls_item_step WITH KEY
          atno = gs_item_step-atno
          step = l_step.
    IF sy-subrc EQ 0.
      l_docnr = ls_item_step-docnr.
    ENDIF.

    <to_f> = l_docnr.
  ENDCASE.
END-OF-DEFINITION.


DEFINE move_valuex .

  IF cl_abap_typedescr=>describe_by_data( <to_f> )->absolute_name = '\TYPE=BAPIUPDATE'.
    <to_fx> = 'X'.
  ELSE.
    <to_fx> = <to_f>.
  ENDIF.

END-OF-DEFINITION.
