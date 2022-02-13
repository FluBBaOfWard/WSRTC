// Bandai WonderSwan RTC emulation

#ifdef __arm__
//
//  WSRTC.s
//  WSRTC
//
//  Created by Fredrik Ahlström on 2022-02-12.
//  Copyright © 2022 Fredrik Ahlström. All rights reserved.
//

#include "WSRTC.i"

	.global wsRtcReset
	.global wsRtcSetSize
	.global wsRtcWriteByte
	.global wsRtcSaveState
	.global wsRtcLoadState
	.global wsRtcGetStateSize
	.global wsRtcSetDateTime
	.global wsRtcUpdate
	.global wsRtcUpdateFrame

	.global wsRtcStatusR
	.global wsRtcCommandW
	.global wsRtcDataR
	.global wsRtcDataW


	.syntax unified
	.arm

#if GBA
	.section .ewram, "ax", %progbits	;@ For the GBA
#else
	.section .text						;@ For anything else
#endif
	.align 2
;@----------------------------------------------------------------------------
wsRtcReset:			;@ In r0 = rtcptr, r1=interrupt func
	.type   wsRtcReset STT_FUNC
;@----------------------------------------------------------------------------
	cmp r1,#0
	adreq r1,dummyFunc
	str r1,[rtcptr,#rtcInterruptPtr]
	ldr r1,=wsRtcSize/4
	b memclr_					;@ Clear WSRtc state
dummyFunc:
	bx lr
;@----------------------------------------------------------------------------
wsRtcSaveState:			;@ In r0=destination, r1=rtcptr. Out r0=state size.
	.type   wsRtcSaveState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
//	add r1,r1,#wsRtcState
	mov r2,#(wsRtcStateEnd-wsRtcState)
	bl memcpy

	ldmfd sp!,{lr}
	ldr r0,=(wsRtcStateEnd-wsRtcState)
	bx lr
;@----------------------------------------------------------------------------
wsRtcLoadState:			;@ In r0=rtcptr, r1=source. Out r0=state size.
	.type   wsRtcLoadState STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{lr}
//	add r0,r0,#wsRtcState
	mov r2,#(wsRtcStateEnd-wsRtcState)
	bl memcpy

	ldmfd sp!,{lr}
;@----------------------------------------------------------------------------
wsRtcGetStateSize:		;@ Out r0=state size.
	.type   wsRtcGetStateSize STT_FUNC
;@----------------------------------------------------------------------------
	ldr r0,=(wsRtcStateEnd-wsRtcState)
	bx lr
;@----------------------------------------------------------------------------
wsRtcSetDateTime:				;@ In r0=rtcptr, r1 ??ssMMHH, r2 = ??DDMMYY
	.type wsRtcSetDateTime STT_FUNC
;@----------------------------------------------------------------------------
	strb r2,[rtcptr,#rtcYear]		;@ Year
	mov r2,r2,lsr#8
	strb r2,[rtcptr,#rtcMonth]		;@ Month
	mov r2,r2,lsr#8
	strb r2,[rtcptr,#rtcDay]		;@ Day
	and r2,r1,#0x3F
	strb r2,[rtcptr,#rtcHour]		;@ Hour
	mov r1,r1,lsr#8
	strb r1,[rtcptr,#rtcMinute]		;@ Minute
	mov r1,r1,lsr#8
	strb r1,[rtcptr,#rtcSecond]		;@ Second
	bx lr
;@----------------------------------------------------------------------------
wsRtcUpdate:		;@ r0=rtcptr. Call every second.
	.type   wsRtcUpdate STT_FUNC
;@----------------------------------------------------------------------------
	ldrb r1,[rtcptr,#rtcSecond]		;@ Seconds
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x60
	movpl r1,#0
	strb r1,[rtcptr,#rtcSecond]
	bmi checkForAlarm

	ldrb r1,[rtcptr,#rtcMinute]		;@ Minutes
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x60
	movpl r1,#0
	strb r1,[rtcptr,#rtcMinute]
	bmi checkForAlarm

	ldrb r1,[rtcptr,#rtcHour]		;@ Hours
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x24
	movpl r1,#0
	strb r1,[rtcptr,#rtcHour]
	bmi checkForAlarm

	ldrb r1,[rtcptr,#rtcDay]		;@ Days
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x32
	movpl r1,#0
	strb r1,[rtcptr,#rtcDay]
	bmi checkForAlarm

	ldrb r1,[rtcptr,#rtcMonth]		;@ Months
	add r1,r1,#0x01
	and r2,r1,#0x0F
	cmp r2,#0x0A
	addpl r1,r1,#0x06
	cmp r1,#0x13
	movpl r1,#1
	strb r1,[rtcptr,#rtcMonth]

checkForAlarm:
	ldrb r1,[rtcptr,#rtcSecond]		;@ Seconds
	cmp r1,#0x00
	ldrbeq r1,[rtcptr,#rtcMinute]	;@ RTC Minutes
	ldrbeq r2,[rtcptr,#rtcAlarmMinute]	;@ ALARM Minutes
	cmpeq r1,r2
	ldrbeq r1,[rtcptr,#rtcHour]		;@ RTC Hours
	ldrbeq r2,[rtcptr,#rtcAlarmHour]	;@ ALARM Hours
	cmpeq r1,r2
	moveq r0,#0x0A
	ldreq r1,[rtcptr,#rtcInterruptPtr]
	bxeq r1

	bx lr
;@----------------------------------------------------------------------------
wsRtcStatusR:			;@ r0=rtcptr
	.type   wsRtcStatusR STT_FUNC
;@----------------------------------------------------------------------------
	ldrb r0,[rtcptr,#rtcCommand]
	orr r0,r0,#0x80			;@ Hack, always ready
	bx lr
;@----------------------------------------------------------------------------
wsRtcDataR:				;@ r0=rtcptr
	.type   wsRtcDataR STT_FUNC
;@----------------------------------------------------------------------------
	ldrb r1,[rtcptr,#rtcCommand]
	ldrb r2,[rtcptr,#rtcIndex]
	add r3,r2,#1
	strb r3,[rtcptr,#rtcIndex]
	cmp r1,#0x15			;@ Read DateTime
	beq readDateTime
	cmp r1,#0x13			;@ Read ???
	bne noRtcData
	cmp r3,#1
	movmi r0,#0				;@ What is expected
	bxmi lr
	b noRtcData
readDateTime:
	cmp r3,#7
	addmi r1,rtcptr,#rtcYear
	ldrbmi r0,[r1,r2]
	bxmi lr
noRtcData:
	mov r1,#0
	strb r1,[rtcptr,#rtcCommand]
	mov r0,#0x80
	bx lr
;@----------------------------------------------------------------------------
wsRtcDataW:				;@ r0=rtcptr, r1 = value
	.type   wsRtcDataW STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r1,r12,lr}
	mov r0,#0xCB
	blx debugIOUnimplW
	ldmfd sp!,{r0,r1,r12,lr}
	ldrb r3,[rtcptr,#rtcCommand]
	ldrb r2,[rtcptr,#rtcIndex]
	cmp r3,#0x14			;@ Write DateTime
	beq writeDateTime
	cmp r3,#0x18			;@ Write Alarm
	bne noWriteData
	add r3,rtcptr,#rtcAlarmHour
	strb r1,[r3,r2]
	add r2,r2,#1
	strb r2,[rtcptr,#rtcIndex]
	cmp r2,#2
	bxmi lr
	b noWriteData
writeDateTime:
	add r3,rtcptr,#rtcYear
	strb r1,[r3,r2]
	add r2,r2,#1
	strb r2,[rtcptr,#rtcIndex]
	cmp r2,#7
	bxmi lr
noWriteData:
	mov r1,#0
	strb r1,[rtcptr,#rtcCommand]
	bx lr
;@----------------------------------------------------------------------------
wsRtcCommandW:			;@ r0=rtcptr, r1 = value
	.type   wsRtcCommandW STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r0,r1,r12,lr}
	mov r0,#0xCB
	blx debugIOUnimplW
	ldmfd sp!,{r0,r1,r12,lr}
	and r1,r1,#0x1F
	strb r1,[rtcptr,#rtcCommand]
	mov r2,#0
	strb r2,[rtcptr,#rtcIndex]

	cmp r1,#0x10			;@ Reset
	beq wsRtcReset
//	cmp r1,#0x12			;@ Set Alarm flag
//	cmp r1,#0x13			;@ Read ???
//	cmp r1,#0x14			;@ Write DateTime
//	cmp r1,#0x15			;@ Read DateTime
//	cmp r1,#0x18			;@ Write Alarm
	// Error?
	bx lr

#endif // #ifdef __arm__
