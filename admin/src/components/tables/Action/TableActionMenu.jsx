import { Dropdown } from "../../ui/dropdown/Dropdown";
import { DropdownItem } from "../../ui/dropdown/DropdownItem";
import { useState } from "react";
import { MoreDotIcon, TrashBinIcon } from "../../../icons";

export default function TableActionMenu({ id, onEdit, onDelete }) {
    const [ isOpen, setIsOpen ] = useState(false);

    function toggleDropdown() { setIsOpen(!isOpen); };

    function closeDropdown() { setIsOpen(false); };

    return (
        <div className="relative">
            <button
                onClick={toggleDropdown}
                className="px-1 py-0 mr-5 text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200"
            >
                <MoreDotIcon className="size-5" />
            </button>

            <Dropdown
                isOpen={isOpen}
                onClose={closeDropdown}
                className="absolute right-0 z-[100px] mt-[10px] flex w-[80px] flex-col rounded-2xl border border-gray-200 bg-white p-2 shadow-theme-lg dark:border-gray-800 dark:bg-gray-dark"
            >
                <ul className="flex flex-col gap-1">
                    {onDelete && (
                        <li>
                            <DropdownItem onClick={() => onDelete(id)} onItemClick={closeDropdown} className="flex justify-center px-2 py-2 font-medium text-gray-700 rounded-lg group text-theme-sm hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/5">
                                <TrashBinIcon className="size-5 text-error-600 dark:text-error-500"/>
                            </DropdownItem>
                        </li>
                    )}
                    <li>
                        <DropdownItem onClick={() => onEdit(id)} onItemClick={closeDropdown} className="flex justify-center px-2 py-2 font-medium text-gray-700 rounded-lg group text-theme-sm hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-white/5">
                                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor" className="size-5">
                                    <path strokeLinecap="round" strokeLinejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10" />
                                </svg>
                        </DropdownItem>
                    </li>
                </ul>
            </Dropdown>
        </div>
    );
}