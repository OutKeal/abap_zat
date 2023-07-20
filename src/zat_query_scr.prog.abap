*&---------------------------------------------------------------------*
*& 包含               ZAT_QUERY_SCR
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_type FOR zatt_type-type,
                                s_werks FOR zatt_head-werks,
                                s_lgort FOR zatt_head-lgort,
                                s_umwrk FOR zatt_head-umwrk,
                                s_umlgo FOR zatt_head-umlgo,
                                s_budat FOR zatt_head-budat,
                                s_exord FOR zatt_head-exord.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  SELECT-OPTIONS:
                                s_atno FOR zatt_head-atno,
                                s_erdat FOR zatt_head-erdat,
                                s_status FOR zatt_head-status.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003.
  PARAMETERS:p_read TYPE char1 AS CHECKBOX.
*PARAMETERS: P_GET64 TYPE CHAR1 AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b3.
