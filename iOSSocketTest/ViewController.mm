//
//  ViewController.m
//  iOSSocketTest
//
//  Created by lunli on 2018/6/12.
//  Copyright © 2018年 lunli. All rights reserved.
//

#include <netinet/tcp.h>
#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <stdlib.h>
#include <sys/ioctl.h>
#include <stdio.h>





@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self startSelectDemo2];
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 服务端
int  serverSockerId = 0;
#define  MAXLINE 4096

- (void)startTcpServer
{
    serverSockerId = -1;
    ssize_t len = -1;
    socklen_t addrlen;
    char buff[MAXLINE];
    struct sockaddr_in ser_addr;
    int yes = 1;
    
    // 第一步：创建socket
    serverSockerId = socket(AF_INET, SOCK_STREAM, 0);
    if(serverSockerId < 0) {
        NSLog(@"Create server socket fail");
        return;
    }
    
    bzero(&ser_addr, sizeof(struct sockaddr_in));
    
    ser_addr.sin_family = AF_INET;
    ser_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    ser_addr.sin_port = htons(1024);
    
    //    将本地地址绑定到所创建的套接字上
    if(bind(serverSockerId, (struct sockaddr *)&ser_addr, addrlen) < 0) {
        NSLog(@"server connect socket fail");
        return;
    }
    
    //    开始监听是否有客户端连接
    if( listen(serverSockerId, 10) < 0){
        NSLog(@"listen socket error: %s(errno: %d)\n",strerror(errno),errno);
        exit(0);
    }

    NSLog(@"======waiting for client's request======\n");
    
    //设置监听超时, 测试超时是否有效
    struct timeval tv;
    tv.tv_sec  = 3;
    tv.tv_usec = 0;
    NSLog(@"socket accept socket socket fd = %d\n", serverSockerId);
    int ret = setsockopt(serverSockerId, SOL_SOCKET, SO_RCVTIMEO, (const char*) &tv, sizeof(tv));
    NSLog(@"socket accept timeout set 1, set timeout ret = %d\n", ret);
    ret = setsockopt(serverSockerId, SOL_SOCKET, SO_SNDTIMEO, (const char*) &tv, sizeof(tv));
    NSLog(@"socket accept timeout set 2, set timeout ret = %d\n", ret);
    
    while (1) {
        
        int connect_fd;
        //阻塞直到有客户端连接，不然多浪费CPU资源。
        NSLog(@"accept socket start, timeout = %ld secs", tv.tv_sec);
        if( (connect_fd = accept(serverSockerId, (struct sockaddr*)NULL, NULL)) == -1){
            NSLog(@"accept socket error: %s(errno: %d)",strerror(errno),errno);
            continue;
        }
        NSLog(@"accept socket end, timeout = %ld secs", tv.tv_sec);

        NSLog(@"accept connect_fd = %d!\n", connect_fd);

        bzero(buff, sizeof(buff));
        
        while(1){
            
            int recv_len = (int)recv(connect_fd, buff, MAXLINE, 0);
            if (recv_len < 0)
            {
                NSLog(@"Receive Data From Client Error!\n");
                break;
            }
            NSLog(@"%d\n",recv_len);
            NSLog(@"%s\n",buff);
            
        }
        close(connect_fd);
        break;
    }
}

// 利用 select 实现 timeout
- (void)startTcpServerWithSelectTimeout
{
    serverSockerId = -1;
    socklen_t addrlen;
    struct sockaddr_in ser_addr;
    int yes = 1;
    
    // 第一步：创建socket
    serverSockerId = socket(AF_INET, SOCK_STREAM, 0);
    if(serverSockerId < 0) {
        NSLog(@"Create server socket fail");
        return;
    }
    
    if (setsockopt(serverSockerId, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int)) == -1) {
        NSLog(@"setsockopt");
        exit(1);
    }
    
    
    bzero(&ser_addr, sizeof(struct sockaddr_in));
    ser_addr.sin_family = AF_INET;
    ser_addr.sin_port = htons(1937);
    ser_addr.sin_addr.s_addr = htonl(INADDR_ANY);

    
    //    将本地地址绑定到所创建的套接字上
    if(bind(serverSockerId, (struct sockaddr *)&ser_addr, sizeof(ser_addr)) < 0) {
        NSLog(@"server connect socket fail");
        return;
    }
    
    //    开始监听是否有客户端连接
    if( listen(serverSockerId, 10) < 0){
        NSLog(@"listen socket error: %s(errno: %d)\n",strerror(errno),errno);
        exit(0);
    }


    NSLog(@"======waiting for client's request======\n");
    
    //设置监听超时, 测试超时是否有效
    struct timeval tv;
    tv.tv_sec  = 3;
    tv.tv_usec = 0;

    while (1) {
        
        fd_set fd;
        int sin_size;
        int connected = -1;

        FD_ZERO(&fd);
        FD_SET(serverSockerId, &fd);
        
        
        
        tv.tv_sec = 30;
        tv.tv_usec = 0;
        NSLog(@"====== start select 1 ======\n");

        if (select(serverSockerId + 1, &fd, NULL, NULL, &tv) > 0)
        {
            NSLog(@"====== start select 2 ======\n");

            sin_size = sizeof(struct sockaddr_in);
            
            connected = accept(serverSockerId, (struct sockaddr*)NULL, NULL);
            
            NSLog(@"====== start select 3 ======\n");
        }
        
        NSLog(@"====== start select 4 ======\n");
        
        NSLog(@"Connection accepted connected = %d", connected);


        break;
    }
    
    NSLog(@"====== startTcpServerWithSelectTimeout end ======\n");

}


- (void)startDemoTcpServer
{
    int listenfd = 0;
    struct sockaddr_in serv_addr;
    
    listenfd = socket(AF_INET, SOCK_STREAM, 0);
    memset(&serv_addr, '0', sizeof(serv_addr));
    
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    serv_addr.sin_port = htons(1937);
    
    bind(listenfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr));
    
    BOOL _listenForConnections = true;
    listen(listenfd, 10);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"Waiting for connections...");
        while (_listenForConnections)
        {
            __block int connfd = accept(listenfd, (struct sockaddr*)NULL, NULL);
            NSLog(@"Connection accepted connfd = %d", connfd);
            
            char buffer[1024];
            bzero(buffer, 1024);
            NSString *message = @"";
            bool continueReading = true;
            
            do
            {
                recv(connfd , buffer , 1024 , 0);
                int size = strlen(buffer);
                if ((buffer[size-1] == '}' && buffer[size-2] == '{'))
                {
                    continueReading = false;
                    buffer[size-2] = '\0';
                }
                message = [NSString stringWithFormat: @"%@%s", message, buffer];
                
            }while (continueReading);
            NSLog(@"Got message from client");
            
            char* answer = "Hello World";
            write(connfd, answer, strlen(answer));
        }
        
        NSLog(@"Stop listening.");
        close(listenfd);
    });
    
}


#define MYPORT 1937    // the port users will be connecting to
#define BACKLOG 1     // how many pending connections queue will hold
#define BUF_SIZE 200
int fd_A[BACKLOG];     // accepted connection fd
int conn_amount;    // current connection amount

- (void)startSelectDemo2
{
    int sock_fd, new_fd;  // listen on sock_fd, new connection on new_fd
    struct sockaddr_in server_addr;    // server address information
    struct sockaddr_in client_addr; // connector's address information
    socklen_t sin_size;
    int yes = 1;
    char buf[BUF_SIZE];
    int ret;
    int i;
    
    if ((sock_fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
        NSLog(@"socket");
        exit(1);
    }
    
    if (setsockopt(sock_fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int)) == -1) {
        NSLog(@"setsockopt");
        exit(1);
    }
    
    server_addr.sin_family = AF_INET;         // host byte order
    server_addr.sin_port = htons(MYPORT);     // short, network byte order
    server_addr.sin_addr.s_addr = INADDR_ANY; // automatically fill with my IP
    memset(server_addr.sin_zero, '\0', sizeof(server_addr.sin_zero));
    
    if (bind(sock_fd, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
        NSLog(@"bind");
        exit(1);
    }
    
    if (listen(sock_fd, BACKLOG) == -1) {
        NSLog(@"listen");
        exit(1);
    }
    
    NSLog(@"listen port %d\n", MYPORT);
    
    fd_set fdsr;
    int maxsock;
    struct timeval tv;
    
    conn_amount = 0;
    sin_size = sizeof(client_addr);
    maxsock = sock_fd;
    while (1) {
        // initialize file descriptor set
        FD_ZERO(&fdsr);
        FD_SET(sock_fd, &fdsr);
        
        // timeout setting
        tv.tv_sec = 5;
        tv.tv_usec = 0;
        
        // add active connection to fd set
        for (i = 0; i < BACKLOG; i++) {
            if (fd_A[i] != 0) {
                FD_SET(fd_A[i], &fdsr);
            }
        }
        
        ret = select(maxsock + 1, &fdsr, NULL, NULL, &tv);
        if (ret < 0) {
            NSLog(@"select");
            break;
        } else if (ret == 0) {
            NSLog(@"timeout\n");
            continue;
        }
        
        // check every fd in the set
        for (i = 0; i < conn_amount; i++) {
            if (FD_ISSET(fd_A[i], &fdsr)) {
                ret = recv(fd_A[i], buf, sizeof(buf), 0);
                if (ret <= 0) {        // client close
                    NSLog(@"client[%d] close\n", i);
                    close(fd_A[i]);
                    FD_CLR(fd_A[i], &fdsr);
                    fd_A[i] = 0;
                } else {        // receive data
                    if (ret < BUF_SIZE)
                        memset(&buf[ret], '\0', 1);
                    NSLog(@"client[%d] send:%s\n", i, buf);
                }
            }
        }
        
        // check whether a new connection comes
        if (FD_ISSET(sock_fd, &fdsr)) {
            new_fd = accept(sock_fd, (struct sockaddr *)&client_addr, &sin_size);
            if (new_fd <= 0) {
                NSLog(@"accept");
                continue;
            }
            else
            {
                const char *hello = "hello from clent";
                send(new_fd, hello, strlen(hello), 0);
                
                char recvbuf[4096];
                int retry = 0;
                while (retry++ < 3) {
                    
                    memset(recvbuf, 0, 4096);
                    
                    int ret = recv(new_fd, recvbuf, 4096 - 1, 0);
                    
                    if(ret > 0)
                    {
                        NSLog(@"app recv:%s\n",recvbuf);
                    }
                    else
                    {
                        NSLog(@"app recv error ret = %d\n",ret);
                    }
                }
                
                
            }
            
            // add to fd queue
            if (conn_amount < BACKLOG) {
                fd_A[conn_amount++] = new_fd;
                NSLog(@"new connection client[%d] %s:%d\n", conn_amount,
                       inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));
                if (new_fd > maxsock)
                    maxsock = new_fd;
            }
            else {
                NSLog(@"max connections arrive, exit\n");
                send(new_fd, "bye", 4, 0);
                close(new_fd);
                break;
            }
        }
        
        int i;
        NSLog(@"client amount: %d\n", conn_amount);
        for (i = 0; i < BACKLOG; i++) {
            NSLog(@"[%d]:%d  ", i, fd_A[i]);
        }
        NSLog(@"\n\n");    }
    
    // close other connections
    for (i = 0; i < BACKLOG; i++) {
        if (fd_A[i] != 0) {
            close(fd_A[i]);
        }
    }
    
    exit(0);
}
@end
