/*
* Copyright (c) 2019 Apple Inc. All rights reserved.
*
* This document is the property of Apple Inc.
* It is considered confidential and proprietary.
*
* This document may not be reproduced or transmitted in any form,
* in whole or in part, without the express written permission of
* Apple Inc.
*/

#include "mbox.h"
#include <stdarg.h>
#include <stdio.h>

static inline uint64_t msg_get (uint64_t msg, uint32_t width, uint32_t position)
{
  return (msg >> position) & ((1ULL<<width) - 1);
}

static inline uint64_t msg_set (uint64_t val, uint32_t width, uint32_t position)
{
  return ((val << position) & (((1ULL << width) - 1) << position));
}



//Message Class
constexpr uint64_t MBI_MSG_PAYLOAD_BITS {52};
constexpr uint64_t MSG_ROUTE_BITS		{4};
constexpr uint64_t MSG_PAYLOAD_BITS		{MBI_MSG_PAYLOAD_BITS - MSG_ROUTE_BITS};
constexpr uint64_t MSG_ROUTE_SHIFT		{MSG_PAYLOAD_BITS};
constexpr uint64_t MSG_PAYLOAD_SHIFT	{0};
constexpr uint64_t MSG_CMD_BITS			{4};
constexpr uint64_t MSG_CMD_SHIFT		{MSG_PAYLOAD_BITS - MSG_CMD_BITS};




message::message(msg_route_t route, msg_cmd_t command, uint64_t payload)
{
	this->data = 0;

	this->data |= msg_set((uint64_t)route, MSG_ROUTE_BITS, MSG_ROUTE_SHIFT);
	this->data |= msg_set((uint64_t)command, MSG_CMD_BITS, MSG_CMD_SHIFT);
	this->data |= msg_set((uint64_t)payload, MSG_PAYLOAD_BITS, MSG_PAYLOAD_SHIFT);
	printf("%s %d: 0x%llx\n", __FUNCTION__, __LINE__, this->data);
};

uint64_t message::get_message_payload(void) const
{
	uint64_t route = msg_get(data, MSG_ROUTE_BITS, MSG_ROUTE_SHIFT);
	uint64_t command = msg_get(data, MSG_CMD_BITS, MSG_CMD_SHIFT);
	uint64_t payload = msg_get(data, MSG_PAYLOAD_BITS, MSG_PAYLOAD_SHIFT);
	printf("route:\t\t%llx\ncommand:\t%llx\npayload:\t%#llx\n", route, command, payload);
	return 0;
}

void message::set_message_payload(uint64_t payload)
{
	data |= msg_set((uint64_t)payload, MSG_PAYLOAD_BITS, MSG_PAYLOAD_SHIFT);
}

void mbox::set_message_handler(message_handler handler, void* arg) const
{

}


void mbox::send_message(message &msg) const
{
	uint64_t data = msg.get_message_data();
	uint64_t route = msg_get(data, MSG_ROUTE_BITS, MSG_ROUTE_SHIFT);
	uint64_t command = msg_get(data, MSG_CMD_BITS, MSG_CMD_SHIFT);
	uint64_t payload = msg_get(data, MSG_PAYLOAD_BITS, MSG_PAYLOAD_SHIFT);
	printf("EndPoint:\t%x\nroute:\t\t%llx\ncommand:\t%llx\npayload:\t%#llx\n", endpoint, route, command, payload);
}

bool mbox::receive_message(message &msg) const
{
	return true;
}
