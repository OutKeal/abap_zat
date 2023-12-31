*&---------------------------------------------------------------------*
*& 包含               LZAT_GOFZZ
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form fm_zz_move_value
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LS_RULE
*&      <-- FVALUE
*&---------------------------------------------------------------------*
FORM fm_zz_move_value  USING  ls_rule TYPE zatt_step_rule
                       CHANGING fvalue.
  IF g_type = 'Z01'  OR g_type = 'Z02'.
    IF ls_rule-from_fieldalv = 'ITEM' AND ls_rule-from_fname = 'AMOUNT'.
      fvalue = fvalue / 10.
    ENDIF.
  ENDIF.
ENDFORM.
