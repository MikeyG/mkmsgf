; Message data area                     
	PUBLIC	_TXT_MSG_TOO_MANY_SEMAPHORES
_TXT_MSG_TOO_MANY_SEMAPHORES	LABEL	WORD
	PUBLIC	_TXT_MSG_TOO_MANY_SEMAPHORES
_TXT_MSG_TOO_MANY_SEMAPHORES	LABEL	WORD
		DW	END_MSG_TOO_MANY_SEMAPHORES - _TXT_MSG_TOO_MANY_SEMAPHORES - 2
		DB	'MAB0100: '
		DB	'File not found',0DH,0AH
END_MSG_TOO_MANY_SEMAPHORES		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_EXCL_SEM_ALREADY_OWNED
_TXT_MSG_EXCL_SEM_ALREADY_OWNED	LABEL	WORD
	PUBLIC	_TXT_MSG_EXCL_SEM_ALREADY_OWNED
_TXT_MSG_EXCL_SEM_ALREADY_OWNED	LABEL	WORD
		DW	END_MSG_EXCL_SEM_ALREADY_OWNED - _TXT_MSG_EXCL_SEM_ALREADY_OWNED - 2
		DB	'MAB0101:'
		DB	'
'
END_MSG_EXCL_SEM_ALREADY_OWNED		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_SEM_IS_SET
_TXT_MSG_SEM_IS_SET	LABEL	WORD
	PUBLIC	_TXT_MSG_SEM_IS_SET
_TXT_MSG_SEM_IS_SET	LABEL	WORD
		DW	END_MSG_SEM_IS_SET - _TXT_MSG_SEM_IS_SET - 2
		DB	'MAB0102: '
		DB	'Usage: del [driv'
		DB	'e:][path] filena'
		DB	'me',0DH,0AH
END_MSG_SEM_IS_SET		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_TOO_MANY_SEM_REQUESTS
_TXT_MSG_TOO_MANY_SEM_REQUESTS	LABEL	WORD
	PUBLIC	_TXT_MSG_TOO_MANY_SEM_REQUESTS
_TXT_MSG_TOO_MANY_SEM_REQUESTS	LABEL	WORD
		DW	END_MSG_TOO_MANY_SEM_REQUESTS - _TXT_MSG_TOO_MANY_SEM_REQUESTS - 2
		DB	'MAB0103:'
		DB	'
'
END_MSG_TOO_MANY_SEM_REQUESTS		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_INVALID_AT_INTERRUPT_TIME
_TXT_MSG_INVALID_AT_INTERRUPT_TIME	LABEL	WORD
	PUBLIC	_TXT_MSG_INVALID_AT_INTERRUPT_TIME
_TXT_MSG_INVALID_AT_INTERRUPT_TIME	LABEL	WORD
		DW	END_MSG_INVALID_AT_INTERRUPT_TIME - _TXT_MSG_INVALID_AT_INTERRUPT_TIME - 2
		DB	'%1 files copied',0DH,0AH
END_MSG_INVALID_AT_INTERRUPT_TIME		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_SEM_OWNER_DIED
_TXT_MSG_SEM_OWNER_DIED	LABEL	WORD
	PUBLIC	_TXT_MSG_SEM_OWNER_DIED
_TXT_MSG_SEM_OWNER_DIED	LABEL	WORD
		DW	END_MSG_SEM_OWNER_DIED - _TXT_MSG_SEM_OWNER_DIED - 2
		DB	'MAB0105: '
		DB	'Warning! All dat'
		DB	'a will be destro'
		DB	'yed!',0DH,0AH
END_MSG_SEM_OWNER_DIED		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_ERROR_DISK_CHANGE
_TXT_MSG_ERROR_DISK_CHANGE	LABEL	WORD
	PUBLIC	_TXT_MSG_ERROR_DISK_CHANGE
_TXT_MSG_ERROR_DISK_CHANGE	LABEL	WORD
		DW	END_MSG_ERROR_DISK_CHANGE - _TXT_MSG_ERROR_DISK_CHANGE - 2
		DB	'MAB0106:'
		DB	'
'
END_MSG_ERROR_DISK_CHANGE		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_DISK_CHANGE
_TXT_MSG_DISK_CHANGE	LABEL	WORD
	PUBLIC	_TXT_MSG_DISK_CHANGE
_TXT_MSG_DISK_CHANGE	LABEL	WORD
		DW	END_MSG_DISK_CHANGE - _TXT_MSG_DISK_CHANGE - 2
		DB	'MAB0107:'
		DB	'
'
END_MSG_DISK_CHANGE		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_DRIVE_LOCKED
_TXT_MSG_DRIVE_LOCKED	LABEL	WORD
	PUBLIC	_TXT_MSG_DRIVE_LOCKED
_TXT_MSG_DRIVE_LOCKED	LABEL	WORD
		DW	END_MSG_DRIVE_LOCKED - _TXT_MSG_DRIVE_LOCKED - 2
		DB	'Do you wish to a'
		DB	'pply these patch'
		DB	'es (Y or N)? '
END_MSG_DRIVE_LOCKED		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_BROKEN_PIPE
_TXT_MSG_BROKEN_PIPE	LABEL	WORD
	PUBLIC	_TXT_MSG_BROKEN_PIPE
_TXT_MSG_BROKEN_PIPE	LABEL	WORD
		DW	END_MSG_BROKEN_PIPE - _TXT_MSG_BROKEN_PIPE - 2
		DB	'MAB0109: '
		DB	'Divide overflow',0DH,0AH
END_MSG_BROKEN_PIPE		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_ERROR_OPEN_FAILED
_TXT_MSG_ERROR_OPEN_FAILED	LABEL	WORD
	PUBLIC	_TXT_MSG_ERROR_OPEN_FAILED
_TXT_MSG_ERROR_OPEN_FAILED	LABEL	WORD
		DW	END_MSG_ERROR_OPEN_FAILED - _TXT_MSG_ERROR_OPEN_FAILED - 2
		DB	'Prompt with no 0'
		DB	' at end',0DH,0AH
END_MSG_ERROR_OPEN_FAILED		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_ERROR_FILENAME_LONG
_TXT_MSG_ERROR_FILENAME_LONG	LABEL	WORD
	PUBLIC	_TXT_MSG_ERROR_FILENAME_LONG
_TXT_MSG_ERROR_FILENAME_LONG	LABEL	WORD
		DW	END_MSG_ERROR_FILENAME_LONG - _TXT_MSG_ERROR_FILENAME_LONG - 2
		DB	'Info with 0 at e'
		DB	'nd'
END_MSG_ERROR_FILENAME_LONG		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_DISK_FULL
_TXT_MSG_DISK_FULL	LABEL	WORD
	PUBLIC	_TXT_MSG_DISK_FULL
_TXT_MSG_DISK_FULL	LABEL	WORD
		DW	END_MSG_DISK_FULL - _TXT_MSG_DISK_FULL - 2
		DB	'MAB0112: '
		DB	'Warn with 0 at e'
		DB	'nd'
END_MSG_DISK_FULL		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_NO_SEARCH_HANDLES
_TXT_MSG_NO_SEARCH_HANDLES	LABEL	WORD
	PUBLIC	_TXT_MSG_NO_SEARCH_HANDLES
_TXT_MSG_NO_SEARCH_HANDLES	LABEL	WORD
		DW	END_MSG_NO_SEARCH_HANDLES - _TXT_MSG_NO_SEARCH_HANDLES - 2
		DB	'MAB0113: '
		DB	'Err with 0 at en'
		DB	'd'
END_MSG_NO_SEARCH_HANDLES		LABEL	WORD
		DB		0
	PUBLIC	_TXT_MSG_ERR_INV_TAR_HANDLE
_TXT_MSG_ERR_INV_TAR_HANDLE	LABEL	WORD
	PUBLIC	_TXT_MSG_ERR_INV_TAR_HANDLE
_TXT_MSG_ERR_INV_TAR_HANDLE	LABEL	WORD
		DW	END_MSG_ERR_INV_TAR_HANDLE - _TXT_MSG_ERR_INV_TAR_HANDLE - 2
		DB	'MAB0114: '
		DB	'Hlp with 0 at en'
		DB	'd '
END_MSG_ERR_INV_TAR_HANDLE		LABEL	WORD
		DB		0
