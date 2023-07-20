*&---------------------------------------------------------------------*
*& 包含               ZAT_IMPORT_DAT
*&---------------------------------------------------------------------*


TABLES:zatt_head,zatt_item,zatt_type,sscrfields.

FIELD-SYMBOLS <gs_head> TYPE zats_head.

DATA g_error TYPE char1.

DATA:gt_alv TYPE TABLE OF zats_upload WITH HEADER LINE.
DATA:gt_head TYPE TABLE OF zatt_head WITH HEADER LINE.
DATA:gt_item TYPE TABLE OF zatt_item WITH HEADER LINE.

DATA:gt_control TYPE TABLE OF zatt_control WITH HEADER LINE.
DATA gt_message TYPE TABLE OF esp1_message_wa_type WITH HEADER LINE.

FIELD-SYMBOLS <gt_tab>  TYPE STANDARD TABLE.
FIELD-SYMBOLS <gs_tab>  TYPE any.
FIELD-SYMBOLS <gs_text> TYPE any.
