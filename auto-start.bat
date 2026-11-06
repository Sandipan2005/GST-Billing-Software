@echo off
REM Auto Update & Start - Bharat GST Billing
REM Run this file to automatically check for updates, merge, and start the app

cd /d "D:\Free-GST-Billing-Software"
powershell -ExecutionPolicy Bypass -File "scripts\auto-update-and-start.ps1"