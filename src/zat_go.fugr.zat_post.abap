FUNCTION zat_post.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(IV_TYPE) TYPE  ZATD_TYPE
*"     VALUE(IV_ATNO) TYPE  ZATD_ATNO
*"     VALUE(IV_BUDAT) TYPE  BUDAT
*"  EXPORTING
*"     VALUE(E_STATUS) TYPE  ZATD_STATUS
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

  CALL FUNCTION 'ZAT_CLEAR'.

  g_type = iv_type.
  g_budat = iv_budat.
  gs_head-budat = g_budat.

  SELECT SINGLE * FROM zatt_head
                                WHERE atno = @iv_atno
                                AND type = @iv_type
                                INTO  @gs_head.

  SELECT * FROM zatt_item
                  WHERE atno = @iv_atno
                  INTO TABLE @gt_item.

  SELECT * FROM zatt_item_step
                  WHERE atno = @iv_atno
                  INTO TABLE @gt_item_step.

  IF gs_head IS INITIAL
    OR gt_item[] IS INITIAL
    OR gt_item_step[] IS INITIAL.
    PERFORM frm_add_msg USING 'S'  'ZAT' '000' '获取数据失败' '' '' ''.
  ENDIF.

  PERFORM frm_get_config.
*  PERFORM get_next_msgnr CHANGING g_msgnr. "获取唯一日志流水编号
  IF g_error = 'X'.
    et_return[] = gt_return[].
    RETURN.
  ENDIF.

  PERFORM frm_lock USING gs_head-atno.
  IF g_error = 'X'.
    et_return[] = gt_return[].
    RETURN.
  ENDIF.
  CASE gs_head-status.
    WHEN 'S'.
      PERFORM frm_add_msg USING 'S' 'ZAT' '000' '已经过账，不需要处理' '' '' ''.
    WHEN 'D' OR 'F'.
      PERFORM frm_add_msg USING 'E' 'ZAT' '000' '已经作废，不能要处理' '' '' ''.
    WHEN OTHERS.
      PERFORM frm_step_go.
  ENDCASE.

  PERFORM frm_unlock USING gs_head-atno.

  et_return[] = gt_return[].
  e_status = gs_head-status.

ENDFUNCTION.
