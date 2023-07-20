*&---------------------------------------------------------------------*
*& 包含               ZAT_QUERY_DAT
*&---------------------------------------------------------------------*

TABLES:zatt_head,zatt_item,zatt_type.

DATA:gt_head TYPE TABLE OF zats_head WITH HEADER LINE.
DATA:gt_item TYPE TABLE OF zats_item WITH HEADER LINE.
DATA:gt_msg TYPE TABLE OF zats_message WITH HEADER LINE.
DATA:gt_step TYPE TABLE OF zats_item_step WITH HEADER LINE.

DATA:gt_item_dis TYPE TABLE OF zats_item WITH HEADER LINE.
DATA:gt_msg_dis TYPE TABLE OF zats_message WITH HEADER LINE.
DATA:gt_step_dis TYPE TABLE OF zats_item_step WITH HEADER LINE.

DATA gt_message TYPE TABLE OF esp1_message_wa_type WITH HEADER LINE.

FIELD-SYMBOLS <gs_head> TYPE zats_head.

DATA gv_m TYPE char1.
