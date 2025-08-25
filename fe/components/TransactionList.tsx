import {
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { cn, getSubjectColor } from "@/lib/utils";
import Image from "next/image";
import Link from "next/link";

interface TransactionListProps {
  title: string;
  transactions?: {
    id: string;
    type: "mint" | "breed" | "bridge" | "marketplace";
    subject: string;
    date: string;
    link: string;
  }[];
  classNames?: string;
}

const TransactionList = ({
  title,
  transactions = [],
  classNames,
}: TransactionListProps) => {
  return (
    <article className={cn("companion-list", classNames)}>
      <h2 className="font-bold text-3xl">Recent Transactions</h2>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="text-lg w-2/3">Type</TableHead>
            <TableHead className="text-lg">Subject</TableHead>
            <TableHead className="text-lg text-right">Date</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {transactions?.map(({ id, type, subject, date, link }) => (
            <TableRow key={id}>
              <TableCell>
                <div className="flex items-center gap-2">
                  <Image
                    src={`/icons/${type}.svg`}
                    alt={type}
                    width={20}
                    height={20}
                  />
                  <span className="capitalize">{type}</span>
                </div>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </article>
  );
};

export default TransactionList;
