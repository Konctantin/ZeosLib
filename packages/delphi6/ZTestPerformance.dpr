{*********************************************************}
{                                                         }
{                 Zeos Database Objects                   }
{            Test Suite for Performance Tests             }
{                                                         }
{    Copyright (c) 1999-2004 Zeos Development Group       }
{                                                         }
{*********************************************************}

{*********************************************************}
{ License Agreement:                                      }
{                                                         }
{ This library is free software; you can redistribute     }
{ it and/or modify it under the terms of the GNU Lesser   }
{ General Public License as published by the Free         }
{ Software Foundation; either version 2.1 of the License, }
{ or (at your option) any later version.                  }
{                                                         }
{ This library is distributed in the hope that it will be }
{ useful, but WITHOUT ANY WARRANTY; without even the      }
{ implied warranty of MERCHANTABILITY or FITNESS FOR      }
{ A PARTICULAR PURPOSE.  See the GNU Lesser General       }
{ Public License for more details.                        }
{                                                         }
{ You should have received a copy of the GNU Lesser       }
{ General Public License along with this library; if not, }
{ write to the Free Software Foundation, Inc.,            }
{ 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA }
{                                                         }
{ The project web site is located on:                     }
{   http://www.sourceforge.net/projects/zeoslib.          }
{   http://www.zeoslib.sourceforge.net                    }
{                                                         }
{                                 Zeos Development Group. }
{*********************************************************}

program ZTestPerformance;

{$APPTYPE CONSOLE}

{$I ..\..\test\performance\ZPerformance.inc}

uses
  TestFrameWork,
  TextTestRunner,
  ZTestConfig,
  ZSqlTestCase,
  ZPerformanceTestCase,
  ZTestBdePerformance in '..\..\test\performance\ZTestBdePerformance.pas',
  ZTestPlainPerformance in '..\..\test\performance\ZTestPlainPerformance.pas',
  ZTestDbcPerformance in '..\..\test\performance\ZTestDbcPerformance.pas',
  ZTestDatasetPerformance in '..\..\test\performance\ZTestDatasetPerformance.pas',
  ZTestOldZeosPerformance in '..\..\test\performance\ZTestOldZeosPerformance.pas',
  ZTestDbxPerformance in '..\..\test\performance\ZTestDbxPerformance.pas',
  ZTestIBXPerformance in '..\..\test\performance\ZTestIbxPerformance.pas';

begin
  TestGroup := PERFORMANCE_TEST_GROUP;
  RebuildTestDatabases;
  PerformanceResultProcessor.ProcessResults;
  PerformanceResultProcessor.PrintResults;
end.

