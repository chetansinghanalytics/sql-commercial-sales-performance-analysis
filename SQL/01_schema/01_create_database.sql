/*
Project: Commercial Sales Performance Analysis
File: 01_create_database.sql
Author: Chetan Singh

Purpose:
Create the CommercialSalesAnalysis database used for the project.
*/

IF DB_ID('CommercialSalesAnalysis') IS NULL
BEGIN
    CREATE DATABASE CommercialSalesAnalysis;
END;
GO