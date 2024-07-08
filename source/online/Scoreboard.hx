package online;

import flixel.util.FlxSpriteUtil;

class Scoreboard extends FlxSpriteGroup {
	public var background:FlxSprite;
	var columns:Array<FlxText> = [];
	var rows:Array<Array<FlxText>> = [];

	public var rowHeight:Int;
	public var rowsAmount:Int;

	var selectBox:FlxSprite;
	var selectedRow:Int = -1;

	public function new(width:Int, rowHeight:Int, rowsAmount:Int, columnsLabels:Array<String>, ?rowsValues:Null<Array<Array<Dynamic>>>) {
        super();

		this.rowHeight = rowHeight;
		this.rowsAmount = rowsAmount;

		background = new FlxSprite();
		background.makeGraphic(width, rowHeight * (rowsAmount + 1), FlxColor.TRANSPARENT, true);
		for (rowI in 0...(rowsAmount + 1)) {
			FlxSpriteUtil.drawRect(background, 0, rowHeight * rowI, width, rowHeight, 
				rowI == 0 ? FlxColor.WHITE.getDarkened(0.8) : rowI % 2 == 0 ? FlxColor.WHITE.getDarkened(0.4) : FlxColor.WHITE.getDarkened(0.2)
            );
		}
		for (columnI in 1...columnsLabels.length + 1) {
			FlxSpriteUtil.drawLine(background, width / columnsLabels.length * columnI, rowHeight + 1, width / columnsLabels.length * columnI, background.height, {
				thickness: 4,
				color: FlxColor.WHITE.getDarkened(0.6)
			});
		}
		FlxSpriteUtil.drawRect(background, 0, 0, background.width, background.height, FlxColor.TRANSPARENT, {
			thickness: 6,
			color: FlxColor.BLACK
		});
		background.alpha = 0.9;
        add(background);

		for (columnI in 0...columnsLabels.length) {
			var columnLabel = new FlxText(width / columnsLabels.length * columnI, 0, width / columnsLabels.length);
			columnLabel.setFormat("VCR OSD Mono", rowHeight, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			columnLabel.text = columnsLabels[columnI];
			columns.push(columnLabel);
			add(columnLabel);

			for (rowI in 0...rowsAmount) {
				if (rows.length < rowI + 1)
					rows.push([]);

				var cell = new FlxText(width / columnsLabels.length * columnI, rowHeight * (rowI + 1), width / columnsLabels.length);
				cell.setFormat("VCR OSD Mono", rowHeight, FlxColor.BLACK, LEFT);
				cell.text = "-";
				if (rowsValues != null && rowsValues[columnI] != null && rowsValues[columnI][rowI] != null) // i need rowsValues[columnI]?[rowI]
					cell.text = Std.string(rowsValues[columnI][rowI]);
				rows[rowI].push(cell);
				add(cell);
			}
        }

		selectBox = new FlxSprite();
		selectBox.makeGraphic(width, rowHeight, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawRect(selectBox, 0, 0, selectBox.width, selectBox.height, FlxColor.TRANSPARENT, {
			thickness: 8,
			color: FlxColor.WHITE
		});
		selectBox.alpha = 0;
		add(selectBox);
    }

	public function setCell(row:Int, column:Int, value:Dynamic) {
		rows[row][column].text = Std.string(value);
	}

	public function setRow(row:Int, cells:Array<Dynamic>) {
		for (cell in 0...rows[row].length) {
			rows[row][cell].text = Std.string(cells[cell]);
		}
	}

	public function clearRows() {
		for (row in rows) {
			for (cell in row) {
				cell.text = "-";
			}
		}
	}

	public function selectRow(row:Int) {
		if (row == selectedRow)
			return;

		selectedRow = row;

		selectBox.alpha = row != -1 ? 1 : 0;
		selectBox.y = y + (row + 1) * rowHeight;
		
		for (rowI in 0...rows.length) {
			for (cell in rows[rowI]) {
				cell.alpha = 0.7;
				if (rowI == row)
					cell.alpha = 1;
			}
		}
	}
}