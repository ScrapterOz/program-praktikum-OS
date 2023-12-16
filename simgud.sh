#!/bin/bash

# Inisialisasi file inventaris
inventory_file="inventory.txt"
shipment_file="shipment.txt"

# Buat file inventaris jika belum ada
touch "$inventory_file"

# Buat file pengiriman jika belum ada
touch "$shipment_file"

# Fungsi untuk menampilkan menu
display_menu() {
    option=$(zenity --list --title="Simulasi Gudang" --column="Opsi" "Lihat Inventaris" "Tambah Barang Baru" "Pengiriman Barang" "Hapus Barang" "Urutkan Inventaris" "Tabel Pengiriman Barang" "Keluar" --width=400 --height=300)

    case $? in
        0) ;;  # Continue with the selected option
        *) exit 0 ;;
    esac
}

# Fungsi untuk menampilkan inventaris
display_inventory() {
    formatted_text=""
    while IFS= read -r line; do
        formatted_text+="$line\n"
    done < "$inventory_file"

    zenity --text-info --title="Inventaris Gudang" --width=600 --height=400 --editable --filename=<(echo -e "$formatted_text") --ok-label="OK"
}

# Fungsi untuk menambahkan barang baru
add_item() {
    current_capacity=$(wc -l < "$inventory_file")
    max_capacity=100

    if [ "$current_capacity" -ge "$max_capacity" ]; then
        zenity --error --title="Error" --text="Gudang sudah mencapai batas maksimal kapasitas."
        return
    fi

    id=$(zenity --entry --title="Tambah Barang Baru" --text="Masukkan ID Barang (manual):" --entry-text="" --cancel-label="Menu Utama")

    # Memeriksa apakah tombol "Cancel" ditekan
    if [ "$?" -ne 0 ]; then
        return
    fi

    # Memeriksa apakah ID sudah ada atau belum
    if grep -q "^$id" "$inventory_file"; then
        zenity --error --title="Error" --text="ID Barang sudah ada. Masukkan ID unik."
        return
    fi

    name=$(zenity --entry --title="Tambah Barang Baru" --text="Masukkan Nama Barang:" --entry-text="" --cancel-label="Menu Utama")
    
    # Memeriksa apakah tombol "Cancel" ditekan
    if [ "$?" -ne 0 ]; then
        return
    fi

    description=$(zenity --entry --title="Tambah Barang Baru" --text="Masukkan Deskripsi Barang:" --entry-text="" --cancel-label="Menu Utama")
    if [ "$?" -ne 0 ]; then
        return
    fi

    stock=$(zenity --entry --title="Tambah Barang Baru" --text="Masukkan Stok Awal:" --entry-text="" --cancel-label="Menu Utama")
    if [ "$?" -ne 0 ]; then
        return
    fi

    arrival_date=$(zenity --calendar --title="Pilih Tanggal Kedatangan" --date-format="%Y-%m-%d" --text="Masukkan Tanggal Kedatangan:" --cancel-label="Menu Utama")
    if [ "$?" -ne 0 ]; then
        return
    fi

    arrival_time=$(zenity --entry --title="Pilih Waktu Kedatangan" --text="Masukkan Waktu Kedatangan (HH:MM):" --entry-text="" --cancel-label="Menu Utama")
    if [ "$?" -ne 0 ]; then
        return
    fi

    arrival_datetime="${arrival_date} ${arrival_time}"

    echo "$id | $name | $description | $stock | $arrival_datetime" >> "$inventory_file"

    zenity --info --title="Tambah Barang Baru" --text="Barang berhasil ditambahkan. ID Barang: $id"
}

# Fungsi untuk mengatur pengiriman barang
shipment_item() {
    id=$(zenity --entry --title="Pengiriman Barang" --text="Masukkan ID Barang yang akan dikirim:" --entry-text="" --cancel-label="Menu Utama")

    # Memeriksa apakah tombol "Cancel" ditekan
    if [ "$?" -ne 0 ]; then
        return
    fi

    # Memeriksa apakah ID ada dalam inventaris
    if ! grep -q "^$id[[:space:]]" "$inventory_file"; then
        zenity --error --title="Error" --text="ID Barang tidak ditemukan."
        return
    fi

    shipment_date=$(zenity --calendar --title="Pilih Tanggal Pengiriman" --date-format="%Y-%m-%d" --text="Masukkan Tanggal Pengiriman:" --cancel-label="Menu Utama")
    if [ "$?" -ne 0 ]; then
        return
    fi

    shipment_time=$(zenity --entry --title="Pilih Waktu Pengiriman" --text="Masukkan Waktu Pengiriman (HH:MM):" --entry-text="" --cancel-label="Menu Utama")
    if [ "$?" -ne 0 ]; then
        return
    fi

    shipment_datetime="${shipment_date} ${shipment_time}"

    # Memperbarui waktu pengiriman barang
    sed -i "s/^$id[[:space:]]\(.*[[:space:]]\)[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[[:space:]]\{1\}[0-9]\{2\}:[0-9]\{2\}/$id \1$shipment_datetime/" "$inventory_file"

    # Menyimpan informasi pengiriman pada file shipment.txt
    echo "$id | $shipment_datetime" >> "$shipment_file"

    zenity --info --title="Pengiriman Barang" --text="Barang dengan ID $id berhasil dikirim pada $shipment_datetime."
}

# Fungsi untuk menampilkan tabel barang yang sudah dikirim
display_shipment() {
    formatted_text=""
    while IFS= read -r line; do
        formatted_text+="$line\n"
    done < "$shipment_file"

    zenity --text-info --title="Barang yang Sudah Dikirim" --width=600 --height=400 --editable --filename=<(echo -e "$formatted_text") --ok-label="OK"
}

# Fungsi untuk menghapus barang
delete_item() {
    delete_id=$(zenity --entry --title="Hapus Barang" --text="Masukkan ID Barang yang akan dihapus:")

    # Menghapus baris yang memiliki ID yang sesuai
    sed -i "/^$delete_id[[:space:]]/d" "$inventory_file"

    zenity --info --title="Hapus Barang" --text="Barang berhasil dihapus."
}

# Fungsi untuk mengurutkan inventaris
sort_inventory() {
    sort -o "$inventory_file" "$inventory_file"
    zenity --info --title="Urutkan Inventaris" --text="Inventaris berhasil diurutkan."
}

# Main program
while true; do
    display_menu

    case "$option" in
        "Lihat Inventaris")
            display_inventory
            ;;
        "Tambah Barang Baru")
            add_item
            ;;
        "Pengiriman Barang")
            shipment_item
            ;;
        "Hapus Barang")
            delete_item
            ;;
        "Urutkan Inventaris")
            sort_inventory
            ;;
        "Tabel Pengiriman Barang")
            display_shipment
            ;;
        "Keluar")
            exit 0
            ;;
    esac
done
