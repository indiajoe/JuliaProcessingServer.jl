#!/usr/bin/env python
""" This script is to send numpy assray to the Julia server """
import socket
import numpy as np
import logging
from cStringIO import StringIO

PortOfServer = 8006
Array = np.random.random((3,4,5))*10

def get_RemoteProcessedData(DataCube,port,hostname="localhost"):
    """ Sends the DataCube to server at hostname:port and return the data received back from server """
    client_socket = socket.socket()
    try:
        client_socket.connect((hostname,port))
    except socket.error as e:
        logging.error('Unable to connect to Data Processing server {0}:{1}'.format(hostname,port))
        raise
    logging.info('Sending ndarray of shape {0} to {1}:{2}'.format(DataCube.shape,hostname,port))
    # Send the Array                                                                                          
    f = StringIO()
    np.save(f,DataCube)
    f.seek(0)
    client_socket.sendall(f.read())
    f.close()

    # Now start reading back form the socket                                                                  
    ultimate_buffer = ""
    while True:
        receiving_buffer = client_socket.recv(1024)
        if not receiving_buffer: break
        ultimate_buffer += receiving_buffer

    DataBack = np.load(StringIO(ultimate_buffer))
    logging.info('Received back ndarray of shape {0}'.format(DataBack.shape))
    client_socket.close()
    return DataBack


print('Sending The following array')
print(Array)
ProcessedArray = get_RemoteProcessedData(Array,PortOfServer)
print('Array Received back:')
print(ProcessedArray)

