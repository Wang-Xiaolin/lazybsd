/**
 * @file lazybsd_version.cc
 * @author meng demao (mengdemao19951021@gmail.com)
 * @brief 版本信息获取
 * @version 0.1
 * @date 2022-09-26
 * 
 * @copyright Copyright (c) 2022
 * 
 */
#include <iostream>
#include <config.h>
#include <lazybsd.h>

void lazybsd_version_get(struct lazybsd_version &version)
{
    version.version_major = lazybsd_VERSION_MAJOR;
    version.version_minor = lazybsd_VERSION_MINOR;
    version.version_build = lazybsd_BUILD;
}