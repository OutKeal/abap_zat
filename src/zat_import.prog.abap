*&---------------------------------------------------------------------*
*& Report ZAT_IMPORT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zat_import.

INCLUDE zat_import_dat."定义

INCLUDE zat_import_scr."选择屏幕

INCLUDE zat_import_alv."定义ALV对象

INCLUDE zat_import_f01."功能代码

INITIALIZATION.

  b_down = '下载模板'.
  PERFORM frm_set_list."选择屏幕下拉框

    PERFORM frm_set_file.

AT SELECTION-SCREEN OUTPUT.

AT SELECTION-SCREEN.

  PERFORM frm_download_temp CHANGING sscrfields-ucomm.  "下载模板

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  PERFORM frm_get_excel_f4 CHANGING p_file."F4路径选择

START-OF-SELECTION.

  PERFORM frm_clear."清空变量

  PERFORM frm_get_config."获取配置

  PERFORM frm_upload_data."上载内表到GT_ALV

  PERFORM frm_move_tab."GT_ALV信息转为HEAD/ITEM

  PERFORM frm_check_data."检查数据

  CALL SCREEN 100."调用屏幕显示
