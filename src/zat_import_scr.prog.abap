*&---------------------------------------------------------------------*
*& 包含               ZAT_IMPORT_SCR
*&---------------------------------------------------------------------*
SELECTION-SCREEN:BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.   .
  PARAMETERS: p_typ   LIKE zatt_type-type AS LISTBOX VISIBLE LENGTH 20 USER-COMMAND typ.

SELECTION-SCREEN:END OF  BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b30 WITH FRAME TITLE TEXT-002.
  SELECTION-SCREEN PUSHBUTTON 2(12)  b_down  USER-COMMAND down MODIF ID lod .
SELECTION-SCREEN END OF BLOCK b30.

SELECTION-SCREEN BEGIN OF BLOCK b40 WITH FRAME TITLE TEXT-003.
  PARAMETERS:p_file LIKE rlgrap-filename OBLIGATORY DEFAULT 'D:\' MODIF ID lod MEMORY ID zfile_path.  "导入文件的路径
*  PARAMETERS:p_row TYPE i OBLIGATORY DEFAULT '2' MODIF ID lod.
SELECTION-SCREEN END OF BLOCK b40.