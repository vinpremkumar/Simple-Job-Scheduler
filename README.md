# Simple-Job-Scheduler

A simple Job-Scheduler was programmed using BASH. It utilizes CPU % as a restriction criteria. 

The queueing system used is FIFO

# How to edit it to your application
This code was tested in Centos 7 environment

'''
  #########
  ## Get ps output into individual arrays]
  ########
  APP="python"   ## CHANGE THIS TO YOUR APP NAME
'''
Change the APP variable from "python" to "_<your app name>_"
  
'''
  MAX_CPU_USAGE=200		# Max CPU percentage that can be utilized by the app
				              # If Hyper-threading is enabled, then each thread is considered a CPU
				              # A MAX_CPU_USAGE=200 corresponds to 2 threads being utilized at 100% 
'''
Set the MAX_CPU_USAGE=<number of threads*100>
  _For example_: If you have a 4 core (8 thread) CPU, and you want to use it completely for your application, then set the MAX_CPU_USAGE as 8*100 =>  MAX_CPU_USAGE=800
