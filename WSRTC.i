//
//  WSRTC.i
//  WSRTC
//
//  Created by Fredrik Ahlström on 2022-02-12.
//  Copyright © 2022-2023 Fredrik Ahlström. All rights reserved.
//
// ASM header for
// Bandai WonderSwan RTC emulation.
// Seiko S-3511A RTC behind Bandai 2003.

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
rtcPadding0:		.byte 0
rtcPadding1:		.byte 0
rtcPadding2:		.byte 0
wsRtcStateEnd:

wsRtcSize:
	.previous

;@----------------------------------------------------------------------------

