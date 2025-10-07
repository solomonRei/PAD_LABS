/*
  Warnings:

  - You are about to drop the column `partnerName` on the `Donation` table. All the data in the column will be lost.
  - You are about to drop the column `source` on the `Donation` table. All the data in the column will be lost.
  - You are about to drop the column `source` on the `Expense` table. All the data in the column will be lost.
  - Added the required column `org` to the `Donation` table without a default value. This is not possible if the table is not empty.
  - Added the required column `origin` to the `Donation` table without a default value. This is not possible if the table is not empty.
  - Added the required column `org` to the `Expense` table without a default value. This is not possible if the table is not empty.

*/
-- CreateTable
CREATE TABLE "Partner" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "contactEmail" TEXT,
    "contactPhone" TEXT,
    "status" TEXT NOT NULL DEFAULT 'active',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "totalDonated" DECIMAL NOT NULL DEFAULT 0,
    "donationCount" INTEGER NOT NULL DEFAULT 0
);

-- CreateTable
CREATE TABLE "BalanceSnapshot" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "source" TEXT NOT NULL,
    "totalDonations" DECIMAL NOT NULL,
    "totalExpenses" DECIMAL NOT NULL,
    "balance" DECIMAL NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "period" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "TransactionLog" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "operationType" TEXT NOT NULL,
    "relatedId" TEXT NOT NULL,
    "source" TEXT,
    "amount" DECIMAL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "description" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "performedBy" TEXT,
    "ipAddress" TEXT,
    "userAgent" TEXT
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Debt" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "offender" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "amount" DECIMAL NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" TEXT NOT NULL DEFAULT 'open',
    "settledAt" DATETIME
);
INSERT INTO "new_Debt" ("amount", "createdAt", "id", "offender", "reason", "status") SELECT "amount", "createdAt", "id", "offender", "reason", "status" FROM "Debt";
DROP TABLE "Debt";
ALTER TABLE "new_Debt" RENAME TO "Debt";
CREATE TABLE "new_Donation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "org" TEXT NOT NULL,
    "origin" TEXT NOT NULL,
    "partnerId" TEXT,
    "amount" DECIMAL NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "receivedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "note" TEXT NOT NULL DEFAULT '',
    "transactionId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'confirmed',
    "createdVia" TEXT NOT NULL DEFAULT 'manual',
    "microserviceId" TEXT,
    CONSTRAINT "Donation_partnerId_fkey" FOREIGN KEY ("partnerId") REFERENCES "Partner" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
INSERT INTO "new_Donation" ("amount", "currency", "id", "note", "receivedAt") SELECT "amount", "currency", "id", "note", "receivedAt" FROM "Donation";
DROP TABLE "Donation";
ALTER TABLE "new_Donation" RENAME TO "Donation";
CREATE UNIQUE INDEX "Donation_transactionId_key" ON "Donation"("transactionId");
CREATE TABLE "new_Expense" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "org" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "amount" DECIMAL NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "paidAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "note" TEXT NOT NULL DEFAULT '',
    "transactionId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'confirmed',
    "createdVia" TEXT NOT NULL DEFAULT 'manual',
    "microserviceId" TEXT,
    "receiptUrl" TEXT
);
INSERT INTO "new_Expense" ("amount", "category", "currency", "id", "note", "paidAt") SELECT "amount", "category", "currency", "id", "note", "paidAt" FROM "Expense";
DROP TABLE "Expense";
ALTER TABLE "new_Expense" RENAME TO "Expense";
CREATE UNIQUE INDEX "Expense_transactionId_key" ON "Expense"("transactionId");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

-- CreateIndex
CREATE UNIQUE INDEX "Partner_name_key" ON "Partner"("name");
