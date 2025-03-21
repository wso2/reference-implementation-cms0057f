import React from 'react';
import { Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper } from '@mui/material';

// Utility function to remove duplicates
const removeDuplicates = (data: any[], columns: string[]) => {
  const seen = new Set();
  
  return data.filter((row) => {
    // Create a string key by combining the values from all relevant columns
    const key = columns.map((col) => row[col]).join('|');
    
    if (seen.has(key)) {
      return false; // Duplicate entry, don't include it
    } else {
      seen.add(key); // Mark the row as seen
      return true;   // Include it in the filtered data
    }
  });
};

const DynamicTable = ({ columns, data }:any) => {

  const filteredData = removeDuplicates(data, columns);

  return (
    <TableContainer component={Paper}>
      <Table size="small" aria-label="purchases">
        <TableHead>
          <TableRow>
            {/* Render table headers dynamically */}
            {columns.map((column:string) => (
              <TableCell key={column}>
                {column}
              </TableCell>
            ))}
          </TableRow>
        </TableHead>
        <TableBody>
          {/* Render table rows and cells dynamically */}
          {data.map((row:any, rowIndex:number) => (
            <TableRow key={rowIndex}>
              {columns.map((column:any, colIndex:string) => (
                <TableCell key={colIndex}>
                  {row[column] || 'N/A'}  {/* Display the value or 'N/A' if not present */}
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
};

export default DynamicTable;
