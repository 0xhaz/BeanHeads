import type { Metadata } from "next";
import { Bricolage_Grotesque } from "next/font/google";
import "./globals.css";
import Navbar from "@/components/Navbar";
import { Provider } from "@/provider/client";
import { BeanHeadsProvider } from "@/context/beanheads";
import { BreederProvider } from "@/context/breeder";

const bricolage = Bricolage_Grotesque({
  variable: "--font-bricolage",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Converso",
  description: "Real-time AI Teaching Platform",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${bricolage.variable} antialiased`}>
        <Provider>
          <BreederProvider>
            <BeanHeadsProvider>
              <Navbar />
              {children}
            </BeanHeadsProvider>
          </BreederProvider>
        </Provider>
      </body>
    </html>
  );
}
