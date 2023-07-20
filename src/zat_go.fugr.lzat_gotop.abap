FUNCTION-POOL zat_go.                       "MESSAGE-ID ..

* INCLUDE LZAT_GOD...                        " Local class definition

DATA:
  gt_type      TYPE TABLE OF zatt_type,
  gt_control   TYPE TABLE OF zatt_control,
  gt_step      TYPE TABLE OF zatt_step,
  gt_step_rule TYPE TABLE OF zatt_step_rule,
*  gt_head      TYPE TABLE OF zatt_head,
  gt_item      TYPE TABLE OF zatt_item,
  gt_item_step TYPE TABLE OF zatt_item_step,
  gt_message   TYPE TABLE OF zatt_message,
  gt_return    TYPE TABLE OF bapiret2.

DATA:
  gs_head      TYPE  zatt_head,
  gs_item      TYPE  zatt_item,
  gs_control   TYPE  zatt_control,
  gs_type      TYPE  zatt_type,
  gs_step      TYPE  zatt_step,
  gs_step_rule TYPE  zatt_step_rule,
  gs_item_step TYPE  zatt_item_step,
  gs_message   TYPE  zatt_message,
  gs_return    TYPE bapiret2.

DATA:g_error TYPE char1,
     g_type  TYPE zatd_type,
     g_msgnr TYPE char10,
     g_times TYPE int1,
     g_mblnr TYPE mblnr,
     g_mjahr TYPE mjahr,
     g_budat TYPE budat.

CONSTANTS c_nr TYPE int1 VALUE 1.



FORM init.
  CLEAR: gt_item ,
              gt_control,
              gt_type ,
              gt_step,
              gt_step_rule,
              gt_item_step,
              gt_message,
              gt_return.

  CLEAR: gs_head,
              gs_item ,
              gs_control,
              gs_type ,
              gs_step,
              gs_step_rule,
              gs_item_step,
              gs_message,
              gs_return.

  CLEAR :g_budat,
              g_type,
              g_error,
              g_msgnr,
              g_times,
              g_mblnr,
              g_mjahr.
ENDFORM.
