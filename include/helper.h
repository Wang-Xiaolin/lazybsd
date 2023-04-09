/**
 * @file helper.h
 * @author mengdemao (mengdemao@google.com)
 * @brief freebsd协议栈接口文件
 * @version 0.1
 * @date 2022-09-11
 *
 * @copyright Copyright (c) 2022
 *
 */
#ifndef __HELPER_H__
#define __HELPER_H__

#define CONS_STR(x, y) __CONS_STR(x, y)
#define CNRV_STR(x, y) __CNRV_STR(x, y)

#define __CONS_STR(x, y) x##y
#define __CNRV_STR(x, y) y##x

#define TO_CHR(x) __TO_CHR(x)
#define TO_STR(x) __TO_STR(x)

#define __TO_CHR(x) @x
#define __TO_STR(x) #x

#define TEST_HEAD TEST(TEST_NAME, UNIQUE_ID)

#define UNIQUE_ID __COUNTER__

#endif /* __HELPER_H__ */