FUNCTION ZAT_CHECK.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(IV_TYPE) TYPE  ZATD_TYPE
*"     VALUE(IS_HEAD) TYPE  ZATS_BAPI_HEAD
*"  TABLES
*"      IT_ITEM STRUCTURE  ZATS_BAPI_ITEM
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

  CALL FUNCTION 'ZAT_CLEAR'.

  g_type = iv_type.
  MOVE-CORRESPONDING is_head to gs_head.
  MOVE-CORRESPONDING it_item[] to gt_item[].

  PERFORM frm_get_config.
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

  et_return[] = gt_return[].

ENDFUNCTION.
