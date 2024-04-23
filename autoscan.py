import os
import time


ip = input("Enter IP_Address: ")
print(os.system("clear"))

print("Grabing Port Numbers!!")

print(os.system(f"nmap -F {ip} > scan.txt"))


with open('scan.txt', 'r') as file:

    content = file.readlines()
    line_box = []
    for line in content:
        line = line.strip()     
        if "open" in line:
            line_box.append(line)

grab_box = []       
for box in line_box:
    box = box.split("/")
    grab = box[0]
    grab_box.append(grab)

print(os.system("rm scan.txt"))

print(os.system("clear"))

print("Running Full Scan!!")

terminal = f"nmap -T4 -A -p{','.join(grab_box)} {ip} > full_scan.txt"

print(os.system(terminal))

print(os.system("clear"))
print("Done Check Your File.")

