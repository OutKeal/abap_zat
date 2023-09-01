*****           Implementation of object type ZAT                  *****
INCLUDE <object>.
begin_data object. " Do not change.. DATA is generated
* only private members may be inserted into structure private
DATA:
  " begin of private,
  "   to declare private attributes remove comments and
  "   insert private attributes here ...
  " end of private,
  BEGIN OF key,
    atno LIKE zatt_head-atno,
  END OF key.
end_data object. " Do not change.. DATA is generated

begin_method display changing container.
RANGES s_erdat FOR sy-datum.
APPEND VALUE #( sign = 'I'
                              option = 'BT'
                              low = '20000101'
                              high = '99991231'
                              ) TO s_erdat.
SUBMIT zat_query WITH s_atno = object-key-atno
                              WITH s_erdat IN s_erdat.

end_method.

begin_method zatcreate changing container.
DATA:
  ishead   LIKE zats_bapi_head,
*      IVDOCNUM TYPE ZATT_HEAD-DOCNUM,
  eatno    TYPE zatt_head-atno,
  estatus  TYPE zatt_head-status,
  ititem   LIKE zats_bapi_item OCCURS 0,
  etreturn LIKE bapiret2 OCCURS 0.
swc_get_element container 'IsHead' ishead.
*  SWC_GET_ELEMENT CONTAINER 'IvDocnum' IVDOCNUM.
swc_get_table container 'ItItem' ititem.
swc_get_table container 'EtReturn' etreturn.
CALL FUNCTION 'ZAT_CREATE'
  EXPORTING
    is_head   = ishead
*   IV_DOCNUM = IVDOCNUM
  IMPORTING
    e_atno    = eatno
    e_status  = estatus
  TABLES
    it_item   = ititem
    et_return = etreturn
  EXCEPTIONS
    OTHERS    = 01.
CASE sy-subrc.
  WHEN 0.            " OK
  WHEN OTHERS.       " to be implemented
ENDCASE.
swc_set_element container 'EAtno' eatno.
swc_set_element container 'EStatus' estatus.
swc_set_table container 'ItItem' ititem.
swc_set_table container 'EtReturn' etreturn.
end_method.
