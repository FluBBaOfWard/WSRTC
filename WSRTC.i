//
//  WSRTC.i
//  WSRTC
//
//  Created by Fredrik Ahlström on 2022-02-12.
//  Copyright © 2022 Fredrik Ahlström. All rights reserved.
//
// ASM header for the Bandai WonderSwan RTC emulator

	rtcptr		.req r0
						;@ WSRTC.s
	.struct 0
rtcInterruptPtr:	.long 0
wsRtcState:
rtcCommand:			.byte 0		;@ Command
rtcIndex:			.byte 0
rtcAlarmOnOff:		.byte 0
rtcYear:			.byte 0
rtcMonth:			.byte 0
rtcDay:				.byte 0
rtcWeekDay:			.byte 0
rtcHour:			.byte 0
rtcMinute:			.byte 0
rtcSecond:			.byte 0
rtcAlarmHour:		.byte 0
rtcAlarmMinute:		.byte 0
wsRtcStateEnd:

wsRtcSize:

;@----------------------------------------------------------------------------

