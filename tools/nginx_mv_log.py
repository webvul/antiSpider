#!/usr/bin/python
# -*- coding: utf-8 -*-
import schedule
import datetime,time
import subprocess
import os

def getTimestampFromDatetime(d=None):
    if d is None:
        d = datetime.datetime.now()
    return time.mktime(d.timetuple())


nginxLogFolder = '/data/logs/'
nginxLogPath = os.path.join(nginxLogFolder,'nginx_error_log')
nginxPidPath = '/var/run/nginx.pid'


#每天循环打包nginx的日志
def rotationNginxLog():
    nowTs = int(getTimestampFromDatetime())
    newLogFilePath = os.path.join(nginxLogFolder, 'old_error.{0}.log'.format(nowTs))

    subprocess.call(['sudo mv {0} {1}'.format(nginxLogPath, newLogFilePath)], shell=True)
    subprocess.call(['sudo kill -USR1 `cat {0}`'.format(nginxPidPath)], shell=True)
    time.sleep(1)
    print('rotation nginx log success')

    #开始删除一周前的日志
    delOneWeekyLog()


#删除一周前的日志
def delOneWeekyLog():
    #待删除日志数组
    removeFileList = []
    #生成上周的时间戳
    today = datetime.datetime.now()
    lastWeek = today - datetime.timedelta(days=7)
    lastWeekTs = int(getTimestampFromDatetime(lastWeek))

    #循环遍历文件夹
    for fileName in os.listdir(nginxLogFolder):
        if fileName.startswith('old_error'):
            nameList = fileName.split('.')
            nameTs = int(nameList[1])
            #如果日志文件已经是1周前
            if lastWeekTs > nameTs:
                removeFileList.append(fileName)

    rmLen = len(removeFileList)
    for item in removeFileList:
        removePath = os.path.join(nginxLogFolder, item)
        subprocess.call(['sudo rm -rf {0}'.format(removePath)], shell=True)

    print('rm old log success, length: {0}'.format(rmLen))

if __name__ == '__main__':
    print('start schedule')
    schedule.every().day.at("02:00").do(rotationNginxLog)
    while True:
        schedule.run_pending()
        time.sleep(1)
