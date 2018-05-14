"use strict";

const fs = require("fs")
const csvStringify = require("csv-stringify/lib/sync");

// Load input text file and split into rows
const input = fs.readFileSync("input.txt", "utf8")
const inputRows = input.split("\n")

// Parse every row and split into columns
const outputRows = []
for (const inputRow of inputRows) {
    // The separator is not Space-Colon-Space, but NoBreakSpace-Colon-Space
    const separator = "\u00A0: "
    let columns = inputRow.split(separator)

    // Handle edge cases where the separator appears multiple times in a row
    if (columns.length > 2) {
        columns = [columns[0], columns.slice(1).join(separator)]
    }

    // Sometimes there is no space in front of the colon
    if (columns.length === 1) {
        const separator2 = ": "
        columns = inputRow.split(separator2)

        // Handle edge cases where the separator appears multiple times in a row
        if (columns.length > 2) {
            columns = [columns[0], columns.slice(1).join(separator2)]
        }
    }

    // Insert into output rows
    outputRows.push(columns)
}

// Create CSV
const csvSeparator = ";" // Numbers expects semicolon as separator on systems with a German locale like en-DE
const csvString = csvStringify(outputRows, {delimiter: csvSeparator})

// Save CSV to file
fs.writeFileSync("MedicalTerms.csv", csvString)

// Generate JSON
const sectionNames = ["#", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
const sections = sectionNames.map((name) => { return {name, entries: []} })
const sectionsByName = {}
for (const section of sections) {
    sectionsByName[section.name] = section
}

let section

for (const row of outputRows) {
    if (row.length === 1) {
        section = sectionsByName[row[0]];
        if (!section) {
            section = sectionsByName["#"]
        }
    } else {
        section.entries.push({abbreviation: row[0], term: row[1]})
    }
}

const jsonString = JSON.stringify(sections, null, 2)
fs.writeFileSync("MedicalTerms.json", jsonString)
