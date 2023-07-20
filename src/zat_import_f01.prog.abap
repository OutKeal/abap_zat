*&---------------------------------------------------------------------*
*& 包含               ZAT_IMPORT_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form frm_set_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_set_list .
  DATA: lt_list  TYPE  vrm_values,
        ls_value TYPE vrm_value.

  SELECT * FROM zatt_type
    INTO TABLE @DATA(lt_type).

  LOOP AT lt_type INTO DATA(ls_type).
    IF sy-tabix EQ 1 AND p_typ IS INITIAL.
      p_typ = ls_type-type.
    ENDIF.
    ls_value-key =  ls_type-type.     "这个就是变量P_LIST的值
    ls_value-text = ls_type-type_name.    "这个是TEXT
    APPEND ls_value TO lt_list .
  ENDLOOP.
  IF sy-subrc EQ 0.
    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id     = 'P_TYP'
        values = lt_list.
    IF sy-subrc EQ 0.
      MODIFY SCREEN.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_download_temp
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- SSCRFIELDS_UCOMM
*&---------------------------------------------------------------------*
FORM frm_download_temp  CHANGING p_ucomm.
  CASE p_ucomm.
    WHEN 'DOWN'.
      CHECK p_typ IS NOT INITIAL.
      PERFORM frm_get_config. "获取配置
      PERFORM frm_get_tab ."获取动态内表结构
      IF g_error = 'X'.
        PERFORM frm_pop_msg .
        RETURN.
      ENDIF.
      PERFORM frm_factory_download USING <gt_tab>."内表转为XMS下载输出
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_get_excel_f4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- P_FILE
*&---------------------------------------------------------------------*
FORM frm_get_excel_f4  CHANGING p_p_up.

  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
      def_path         = p_file
      mask             = '*,XLSX,*.XLSX,*.XLS,*.XLS'
      title            = TEXT-001
    IMPORTING
      filename         = p_p_up
    EXCEPTIONS
      inv_winsys       = 1
      no_batch         = 2
      selection_cancel = 3
      selection_error  = 4
      OTHERS           = 5.

  IF sy-subrc <> 0 AND sy-subrc <> 3.
    MESSAGE i000(zat) WITH '选择文件出错'  DISPLAY LIKE 'E'. "选择文件出错
    STOP.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_run
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_upload_data .


  DATA: lv_msg TYPE char40.
  DATA: itab   TYPE STANDARD TABLE OF zalsmex_tabline WITH HEADER LINE.
  DATA: col_count TYPE i.
  CLEAR g_error.

  FIELD-SYMBOLS:<fs_value> TYPE any.

  DATA:lt_control TYPE TABLE OF zatt_control WITH HEADER LINE.
  lt_control[] = gt_control[].
  DELETE lt_control WHERE upload_index = ''.
  SORT lt_control BY upload_index.

  DESCRIBE TABLE lt_control LINES col_count.

  CALL FUNCTION 'ZALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = p_file
      i_begin_col             = '1'
      i_begin_row             = '1'
      i_end_col               = col_count
      i_end_row               = '99999'
    TABLES
      intern                  = itab
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.

  IF sy-subrc <> 0.
    PERFORM frm_add_msg USING 'E' 'ZAT' 060  '' '' '' ''."导入出错,请重新导入
    RETURN.
  ENDIF.

  CLEAR gt_alv[].
  IF itab[] IS NOT INITIAL.
    LOOP AT lt_control.
      IF lt_control-requi = 'X'.
        lt_control-coltext = lt_control-coltext && '*'.
      ENDIF.
      READ TABLE itab WITH KEY row = 1 col = sy-tabix.
      IF sy-subrc EQ 0 AND itab-value = lt_control-coltext.
      ELSE.
        PERFORM frm_add_msg USING 'E' 'ZAT' 000 lt_control-coltext '导入表头与模板不符' '' ''."
        RETURN.
      ENDIF.
    ENDLOOP.

    LOOP AT itab.
      IF itab-row = '1'.
        CONTINUE.
      ENDIF.
      TRANSLATE  itab-value TO UPPER CASE.
      READ TABLE lt_control INDEX itab-col.
      IF sy-subrc EQ 0.
        ASSIGN COMPONENT lt_control-fieldname  OF STRUCTURE gt_alv TO <fs_value>.
        IF sy-subrc EQ 0.
          IF  lt_control-fieldname = 'BUDAT'.
            PERFORM convert_date CHANGING itab-value.
          ENDIF.
          <fs_value> = itab-value.
        ENDIF.
      ENDIF.
      AT END OF row.
        APPEND gt_alv .
        CLEAR gt_alv.
      ENDAT.
    ENDLOOP.
  ELSE.
    PERFORM frm_add_msg USING 'E' 'ZAT' 000  '请选择正确模板' '' '' ''."请选择正确模板
    RETURN.
  ENDIF.

  SORT gt_alv BY exord.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_get_tab
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_get_tab .
  TYPES: BEGIN OF ty_abap_componentdescr,   "用于生成动态内表
           name       TYPE string,
           type       TYPE REF TO cl_abap_datadescr,
           as_include TYPE abap_bool,
           suffix     TYPE string,
         END OF ty_abap_componentdescr.
  DATA: gcr_ref_tab TYPE REF TO cl_abap_tabledescr.
  DATA: gr_ref_tab TYPE REF TO data.
  DATA: gr_ref_line TYPE REF TO data.
  DATA: gcr_ref_line TYPE REF TO cl_abap_structdescr.
  DATA: lt_abap_componentdescr TYPE STANDARD TABLE OF ty_abap_componentdescr WITH KEY name,
        ls_abap_componentdescr TYPE ty_abap_componentdescr.
  DATA: ls_fieldname TYPE fieldname.
  DATA: lt_dd03l TYPE TABLE OF dd03l WITH HEADER LINE.
  DATA:l_tabname TYPE tabname.

  SELECT * FROM dd03l INTO TABLE lt_dd03l WHERE tabname = 'ZATT_HEAD' OR tabname = 'ZATT_ITEM'.

  SORT gt_control BY upload_index.

  LOOP AT gt_control WHERE type = p_typ AND upload_index <> ''.
    CASE gt_control-fieldalv.
      WHEN 'HEAD'.l_tabname = 'ZATT_HEAD'.
      WHEN 'ITEM'.l_tabname = 'ZATT_ITEM'.
      WHEN OTHERS.        CONTINUE.
    ENDCASE.

    READ TABLE lt_dd03l WITH KEY tabname = l_tabname fieldname = gt_control-fieldname .
    IF sy-subrc NE 0 .
      PERFORM frm_add_msg USING 'E' 'ZAT' 000  '导入模板配置错误' '' '' ''."导入模板配置错误
      RETURN.
    ENDIF.

    IF lt_dd03l-rollname IS NOT INITIAL.
      ls_abap_componentdescr-name = gt_control-fieldname.  "用于生成动态内表
      ls_abap_componentdescr-type ?= cl_abap_typedescr=>describe_by_name( lt_dd03l-rollname ).
    ELSE.
      ls_fieldname = l_tabname && '-' && gt_control-fieldname.
      ls_abap_componentdescr-name = gt_control-fieldname.  "用于生成动态内表
      ls_abap_componentdescr-type ?= cl_abap_typedescr=>describe_by_data( ls_fieldname ).
    ENDIF.
    APPEND ls_abap_componentdescr TO lt_abap_componentdescr.
    CLEAR ls_abap_componentdescr.
  ENDLOOP.

  ls_abap_componentdescr-name = 'KEY'.  "用于生成动态内表
  ls_abap_componentdescr-type ?= cl_abap_typedescr=>describe_by_name( 'STRING' ).
  APPEND ls_abap_componentdescr TO lt_abap_componentdescr.
  CLEAR ls_abap_componentdescr.


  IF lt_abap_componentdescr[] IS INITIAL.
    PERFORM frm_add_msg USING 'E' 'ZAT' 000  '没有配置导入模板' '' '' ''."没有配置导入模板
    RETURN.
  ENDIF.

  gcr_ref_line ?= cl_abap_structdescr=>create( p_components = lt_abap_componentdescr ).

  IF sy-subrc = 0.
    CREATE DATA gr_ref_line TYPE HANDLE gcr_ref_line.
    ASSIGN gr_ref_line->* TO <gs_tab>.
    gcr_ref_tab = cl_abap_tabledescr=>create( p_line_type = gcr_ref_line ).
    IF sy-subrc = 0.
      CREATE DATA gr_ref_tab TYPE HANDLE gcr_ref_tab.
      ASSIGN gr_ref_tab->* TO <gt_tab>.
    ENDIF.
  ELSE.
    PERFORM frm_add_msg USING 'E' 'ZAT' 000  '导入模板配置错误' '' '' ''."导入模板配置错误
    RETURN.
  ENDIF.
ENDFORM.

FORM frm_add_msg USING msgty msgid msgno msgv1 msgv2 msgv3 msgv4.
  IF msgty = 'E' OR msgty =  'A'.
    g_error = 'X'.
  ENDIF.
  CLEAR gt_message.
  gt_message-msgid = msgid .
  gt_message-msgty = msgty .
  gt_message-msgno = msgno .
  gt_message-msgv1 = msgv1 .
  gt_message-msgv2 = msgv2 .
  gt_message-msgv3 = msgv3 .
  gt_message-msgv4 = msgv4 .
  APPEND gt_message.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_pop_msg
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_pop_msg .
  CALL FUNCTION 'C14Z_MESSAGES_SHOW_AS_POPUP'
    TABLES
      i_message_tab = gt_message[].
  CLEAR gt_message[].
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_factory_download
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> <GT_TAB>
*&---------------------------------------------------------------------*

FORM frm_factory_download USING gt_table."下载动态模板

  DATA: gr_table   TYPE REF TO cl_salv_table.
  DATA: lv_filename TYPE string.

  cl_salv_table=>factory(   IMPORTING  r_salv_table = gr_table CHANGING t_table = gt_table ).

  DATA: lr_functions TYPE REF TO cl_salv_functions_list.

  lr_functions = gr_table->get_functions( ).
*lr_functions->set_default( abap_true ).
  lr_functions->set_all( abap_true ).
  DATA: lr_columns TYPE REF TO cl_salv_columns.

  lr_columns = gr_table->get_columns( ).
  lr_columns->set_optimize( abap_true ).

  DATA: lr_column TYPE REF TO cl_salv_column.
  DATA: lv_short_text TYPE char10.
  DATA: lv_middle_text TYPE char20.
  DATA: lv_long_text TYPE char40.

  LOOP AT gt_control WHERE type = p_typ AND upload_index <> '' .
    IF gt_control-requi IS NOT INITIAL.
      gt_control-coltext = gt_control-coltext && '*'.
    ENDIF.
    lr_column = lr_columns->get_column( EXPORTING columnname = gt_control-fieldname ).
    lv_short_text = gt_control-coltext.
    lv_middle_text = gt_control-coltext.
    lv_long_text = gt_control-coltext.
    lr_column->set_short_text( lv_short_text ) .
    lr_column->set_medium_text( lv_middle_text ) .
    lr_column->set_long_text( lv_long_text ) .
    lr_column->set_alignment( 3 ) .
    lr_column->set_optimized( 'X' ) .
  ENDLOOP.

  DATA xstring TYPE xstring.
  xstring = gr_table->to_xml( '10' ).

  lv_filename = p_typ  && TEXT-004 && '.XLSX' .

  PERFORM download_xml_to_file USING lv_filename xstring.

ENDFORM.

FORM download_xml_to_file USING default_filename TYPE string
      content          TYPE xstring.

  DATA:
        l_filename TYPE string.

  PERFORM save_dialog USING default_filename CHANGING l_filename.

  cl_salv_data_services=>download_xml_to_file(
  filename = l_filename
  xcontent = content ).

ENDFORM.                    " download_xml_to_file

FORM save_dialog USING    default_filename TYPE string
CHANGING filename         TYPE string.

  DATA:
    l_path     TYPE string,
    l_fullpath TYPE string.

  CALL METHOD cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      default_file_name = default_filename
    CHANGING
      path              = l_path
      filename          = filename
      fullpath          = l_fullpath ).

ENDFORM.


FORM frm_import_data USING p_file TYPE rlgrap-filename i_begin_row TYPE i.



ENDFORM.                    " IMPORT_DATA
*&---------------------------------------------------------------------*
*& Form convert_date
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- ITAB_VALUE
*&---------------------------------------------------------------------*

FORM convert_date CHANGING value.
  DATA:year TYPE char4.
  DATA:month TYPE char2.
  DATA:day TYPE char2.
  DATA:len(3) TYPE i.
  DATA:flag TYPE char1.
  DATA:datum TYPE sy-datum.

  len = strlen( value ).

  IF len > 10.
    PERFORM frm_add_msg USING 'E' 'ZAFO' 064  '' '' '' ''."日期格式错误
    RETURN.
  ENDIF.

  FIND '.' IN value.
  IF sy-subrc EQ 0.
    flag = '.'.
  ENDIF.

  FIND '/' IN value.
  IF sy-subrc EQ 0.
    flag = '/'.
  ENDIF.

  FIND '-' IN value.
  IF sy-subrc EQ 0.
    flag = '-'.
  ENDIF.

  IF flag IS INITIAL .
    IF len <> 8.
      PERFORM frm_add_msg USING 'E' 'ZAT' 000  '日期格式错误' '' '' ''."
      RETURN.
    ELSE.
      datum = value.
    ENDIF.
  ELSE.

    SPLIT value AT flag INTO year month day.



    DO 4 - strlen( year ) TIMES.
      year = '0' && year.
    ENDDO.

    DO 2 - strlen( month ) TIMES.
      month = '0' && month.
    ENDDO.

    DO 2 - strlen( day ) TIMES.
      day = '0' && day.
    ENDDO.

    value = year && month && day.
    datum = value.
  ENDIF.

  CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
    EXPORTING
      date                      = datum
    EXCEPTIONS
      plausibility_check_failed = 1
      OTHERS                    = 2.
  IF sy-subrc <> 0.
    PERFORM frm_add_msg USING 'E' 'ZAFO' 000  '日期格式错误' '' '' ''."日期格式错误
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_sort_tab
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_sort_tab .
  DATA: lt_sort TYPE abap_sortorder_tab,
        ls_sort LIKE LINE OF lt_sort.

  ls_sort-name = 'KEY'.  "栏位名
  ls_sort-astext = ''.     "As Text：猜测是转换成文本类型来排序
  ls_sort-descending = ''. "空：升序、X：降序
  APPEND ls_sort TO lt_sort.
  CLEAR ls_sort.

  SORT <gt_tab> BY (lt_sort).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_GET_CONFIG
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_get_config .
  SELECT * FROM zatt_control
    WHERE type = @p_typ
    INTO TABLE @gt_control.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_check_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_check_data .
  DATA:ls_head TYPE zatt_head .
  DATA:lt_item TYPE TABLE OF zatt_item WITH HEADER LINE.
  DATA:lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE.
  DATA:l_text TYPE char100.

  LOOP AT gt_head INTO DATA(lg_head)
                                  GROUP BY ( exord = lg_head-exord
                                  size = GROUP SIZE )
                                  INTO DATA(lt_group).
    IF lt_group-size > 1.
      PERFORM frm_set_icon USING lt_group-exord icon_red_light '该外部参考有不一致的抬头信息' ''.
      CONTINUE.
    ENDIF.

    CLEAR: ls_head,lt_item,lt_item[],lt_return,lt_return[].

    LOOP AT GROUP lt_group INTO DATA(ls_group).
      MOVE-CORRESPONDING ls_group TO ls_head.
    ENDLOOP.

    LOOP AT gt_item WHERE exord = ls_head-exord.
      APPEND gt_item TO lt_item.
    ENDLOOP.

    CALL FUNCTION 'ZAT_CHECK'
      EXPORTING
        iv_type   = p_typ
        is_head   = ls_head
      TABLES
        it_item   = lt_item[]
        et_return = lt_return[].

    LOOP AT lt_return WHERE type = 'E' OR type = 'A'.
      PERFORM frm_add_msg USING lt_return-type lt_return-id lt_return-number
            lt_return-message_v1
            lt_return-message_v2
            lt_return-message_v3
            lt_return-message_v4.
      IF l_text IS INITIAL.
        MESSAGE ID lt_return-id TYPE lt_return-type NUMBER lt_return-number
        INTO l_text
        WITH lt_return-message_v1
        lt_return-message_v2
        lt_return-message_v3
        lt_return-message_v4.
      ENDIF.
    ENDLOOP.

    IF sy-subrc EQ 0.
      PERFORM frm_set_icon USING lt_group-exord icon_red_light l_text ''.
    ELSE.
      PERFORM frm_set_icon USING lt_group-exord icon_green_light '检查通过' ''.
    ENDIF.
  ENDLOOP.

  IF gt_message[] IS NOT INITIAL.
    PERFORM frm_pop_msg.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_clear
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_clear .
  CLEAR :gt_alv,gt_head,gt_item,gt_control,gt_message.
  CLEAR :gt_alv[],gt_head[],gt_item[],gt_control[],gt_message[].

ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_move_tab
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_move_tab .
  FIELD-SYMBOLS:
    <fs_value1> TYPE any,
    <fs_value2> TYPE any.
  DATA:l_line TYPE mb_line_id.

  LOOP AT gt_alv INTO DATA(ls_alv)
        GROUP BY ( key = ls_alv-exord )
  INTO DATA(lt_group).

    LOOP AT GROUP lt_group INTO DATA(ls_group).
      LOOP AT gt_control WHERE fieldalv = 'HEAD' AND upload_index <> ''.
        ASSIGN COMPONENT gt_control-fieldname OF STRUCTURE ls_group TO <fs_value1>.
        CHECK sy-subrc EQ 0.
        ASSIGN COMPONENT gt_control-fieldname OF STRUCTURE gt_head TO <fs_value2>.
        CHECK sy-subrc EQ 0.
        <fs_value2> = <fs_value1>.
      ENDLOOP.
      IF  gt_head IS NOT INITIAL.
        gt_head-exord = ls_group-exord.
        APPEND gt_head.
        CLEAR gt_head.
      ENDIF.

      LOOP AT gt_control WHERE fieldalv = 'ITEM' AND upload_index <> ''.
        ASSIGN COMPONENT gt_control-fieldname OF STRUCTURE ls_group TO <fs_value1>.
        CHECK sy-subrc EQ 0.
        ASSIGN COMPONENT gt_control-fieldname OF STRUCTURE gt_item TO <fs_value2>.
        CHECK sy-subrc EQ 0.
        <fs_value2> = <fs_value1>.
      ENDLOOP.
      IF  gt_item IS NOT INITIAL.
        gt_item-exord = ls_group-exord.
        APPEND gt_item.
        CLEAR gt_item.
      ENDIF.
    ENDLOOP.
  ENDLOOP.

  SORT gt_head.
  SORT gt_item BY exord matnr.

  DELETE ADJACENT DUPLICATES FROM gt_head.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_set_icon
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_GROUP_EXORD
*&      --> ICON_RED_LIGHT
*&      --> P_
*&---------------------------------------------------------------------*
FORM frm_set_icon  USING exord
                            icon
                            text
                            atno.
  LOOP AT gt_alv WHERE exord = exord.
    gt_alv-icon = icon.
    gt_alv-text = text.
    gt_alv-atno = atno.
    MODIFY gt_alv.
    CLEAR gt_alv.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_at_create
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_at_create .
  DATA:lt_index_rows TYPE  lvc_t_row,
       ls_index_rows TYPE  lvc_s_row,
       lt_row_no     TYPE  lvc_t_roid.
  DATA:lt_head TYPE TABLE OF zatt_head WITH HEADER LINE.
  DATA:lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE.

  CALL METHOD g_grid_100->get_selected_rows
    IMPORTING
      et_index_rows = lt_index_rows
      et_row_no     = lt_row_no.

  IF lt_index_rows[] IS INITIAL.
    MESSAGE '请选择抬头行' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  CLEAR gt_message[].
  CLEAR lt_head[].
  LOOP AT lt_index_rows INTO ls_index_rows.
    READ TABLE gt_alv INDEX ls_index_rows-index.
    CHECK sy-subrc EQ 0.
    IF gt_alv-icon = icon_green_light.
      lt_head-exord = gt_alv-exord.
      APPEND lt_head.
      CLEAR lt_head.
    ENDIF.
  ENDLOOP.
  SORT lt_head BY exord.
  DELETE ADJACENT DUPLICATES FROM lt_head COMPARING exord.
  IF lt_head[] IS INITIAL.
    MESSAGE '未选择有效行' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT lt_head.
    PERFORM frm_at_create_singel USING lt_head-exord.
  ENDLOOP.

  IF gt_message[] IS NOT INITIAL.
    PERFORM frm_pop_msg.
  ENDIF.
  PERFORM f_refresh_grid_alv USING g_grid_100.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form FRM_AT_CREATE_SINGEL
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_at_create_singel USING exord.

  DATA:ls_head TYPE  zats_bapi_head.
  DATA:lt_item TYPE TABLE OF zats_bapi_item WITH HEADER LINE.
  DATA:l_text TYPE char100.
  DATA:lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE.

  READ TABLE gt_head WITH KEY exord = exord.
  CHECK sy-subrc EQ 0.
  MOVE-CORRESPONDING gt_head TO ls_head.
  LOOP AT gt_item WHERE exord = exord.
    MOVE-CORRESPONDING gt_item TO lt_item.
    APPEND lt_item.
  ENDLOOP.
  ls_head-type = p_typ.

  CALL FUNCTION 'ZAT_CREATE'
    EXPORTING
      is_head   = ls_head
    IMPORTING
      e_atno    = gt_head-atno
    TABLES
      it_item   = lt_item[]
      et_return = lt_return[].

  LOOP AT lt_return WHERE type = 'E' OR type = 'A'.
    PERFORM frm_add_msg USING lt_return-type lt_return-id lt_return-number
          lt_return-message_v1
          lt_return-message_v2
          lt_return-message_v3
          lt_return-message_v4.
    IF l_text IS INITIAL.
      MESSAGE ID lt_return-id TYPE lt_return-type NUMBER lt_return-number
      INTO l_text
      WITH lt_return-message_v1
      lt_return-message_v2
      lt_return-message_v3
      lt_return-message_v4.
    ENDIF.
  ENDLOOP.
  IF sy-subrc EQ 0.
    PERFORM frm_set_icon USING exord icon_red_light l_text ''.
  ELSE.
    PERFORM frm_add_msg USING 'S' 'ZAT' 000 '外部编号' exord '创建成功，交易编号为' gt_head-atno.
    PERFORM frm_set_icon USING exord icon_complete '创建成功' gt_head-atno .
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_goto_query
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_goto_query .
  RANGES: r_atno FOR zatt_head-atno.
  CLEAR r_atno[].
  LOOP AT gt_alv WHERE atno <> ''.
    APPEND |IEQ{ gt_alv-atno }| TO r_atno.
  ENDLOOP.
  SUBMIT zat_query WITH s_atno IN r_atno.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form frm_set_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM frm_set_file .
  DATA:l_string TYPE string.
  CALL METHOD cl_gui_frontend_services=>get_desktop_directory
    CHANGING
      desktop_directory    = l_string
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4.
  CALL METHOD cl_gui_cfw=>flush.

  IF l_string IS NOT INITIAL.
    p_file = l_string && '\'.
  ENDIF.
ENDFORM.
