*&---------------------------------------------------------------------*
*& REPORT ZAT_RULE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zat_rule.

INCLUDE zat_rule_top.

INCLUDE zat_rule_abap_display.

INCLUDE zat_rule_f01.

INCLUDE zat_rule_pbo_pai.

START-OF-SELECTION.

  PERFORM frm_get_data.

  IF gt_rule[] IS INITIAL.
    STOP.
  ELSEIF lines( gt_rule ) = 1.
    gs_rule =  gt_rule[ 1 ].
    PERFORM frm_get_single_data.
    CALL SCREEN 100.
  ELSE.
    g_falv_list = zcl_falv=>create( CHANGING ct_table = gt_rule ).
    g_falv_list->display( ).
  ENDIF.
