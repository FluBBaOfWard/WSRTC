//
//  WSRTC.i
//  Bandai WonderSwan RTC emulation.
//
//  Created by Fredrik Ahlström on 2022-02-12.
//  Copyright © 2022-2024 Fredrik Ahlström. All rights reserved.
//
// Seiko S-3511A RTC behind Luxsor 2003.

#if !__ASSEMBLER__
	#error This header file is only for use in assembly files!
#endif

	rtcptr		.req r0
						;@ WSRTC.s
	.struct 0
rtcInterruptPtr:	.long 0
wsRtcState:
rtcCommand:			.byte 0		;@ Command
rtcIndex:			.byte 0
rtcLength:			.byte 0
rtcStatus:			.byte 0
rtcYear:			.byte 0
rtcMonth:			.byte 0
rtcDay:				.byte 0
rtcWeekDay:			.byte 0
rtcHour:			.byte 0
rtcMinute:			.byte 0
rtcSecond:			.byte 0
rtcAlarmH:			.byte 0
rtcAlarmM:			.byte 0
rtcData:			.byte 0
rtcPadding0:		.byte 0
rtcPadding1:		.byte 0
wsRtcStateEnd:

wsRtcSize:
	.previous

;@----------------------------------------------------------------------------

