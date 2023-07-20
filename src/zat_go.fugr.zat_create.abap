FUNCTION zat_create.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(IS_HEAD) LIKE  ZATS_BAPI_HEAD STRUCTURE  ZATS_BAPI_HEAD
*"  EXPORTING
*"     VALUE(E_ATNO) LIKE  ZATT_HEAD-ATNO
*"     VALUE(E_STATUS) LIKE  ZATT_HEAD-STATUS
*"  TABLES
*"      IT_ITEM STRUCTURE  ZATS_BAPI_ITEM
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  CALL FUNCTION 'ZAT_CLEAR'.

  g_type = is_head-type.
  g_budat = is_head-budat.
  MOVE-CORRESPONDING is_head TO gs_head.
  MOVE-CORRESPONDING it_item[] TO gt_item[].

  PERFORM frm_get_config."获取配置
  IF g_error = 'X'.
    et_return[] = gt_return[].
    RETURN.
  ENDIF.

  PERFORM frm_exord_check ."检查重复性
  IF g_error = 'X'.
    et_return[] = gt_return[].
    RETURN.
  ENDIF.

  PERFORM frm_check_head_data."动态检查抬头
  IF g_error = 'X'.
    et_return[] = gt_return[].
    RETURN.
  ENDIF.

  PERFORM frm_check_item_data."动态检查项目
  IF g_error = 'X'.
    et_return[] = gt_return[].
    RETURN.
  ENDIF.

  PERFORM get_next_atno CHANGING gs_head-atno. "获取单号
  IF g_error = 'X'.
    et_return[] = gt_return[].
    RETURN.
  ENDIF.

  PERFORM frm_init_head."初始化抬头单号、默认值

  PERFORM frm_init_item."初始化项目单号、行号、默认值

  PERFORM frm_init_item_text."处理物料描述/单位

  PERFORM frm_init_item_step."初始化处理步骤

  PERFORM frm_move_head_to_item."抬头值刷入项目

  PERFORM frm_save_data."保存表

  IF gs_type-immed = 'X'.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.
    PERFORM frm_step_go."步骤执行
  ELSE.
    PERFORM frm_add_msg
         USING 'S'
                     'ZAT'
                     '000'
                     '自动交易'
                     gs_head-atno
                     '创建成功，未执行' ''.
  ENDIF.

  et_return[] = gt_return[].
  e_atno = gs_head-atno.
  e_status = gs_head-status.

ENDFUNCTION.
